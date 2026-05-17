defmodule AzarApp.Sorteos do
  @moduledoc false

  import Ecto.Query, warn: false
  alias AzarApp.Repo
  alias AzarApp.Sorteos.{Sorteo, Ticket}
  alias AzarApp.Cuentas

  @doc """
  Breve: get_sorteo.
  """
  def get_sorteo!(id), do: Repo.get!(Sorteo, id) |> Repo.preload([:tickets])

  @doc """
  Breve: get_sorteo_con_tickets.
  """
  def get_sorteo_con_tickets!(id) do
    Sorteo
    |> Repo.get!(id)
    |> Repo.preload(tickets: [:usuario])
  end

  @doc """
  Breve: list_sorteos.
  """
  def list_sorteos do
    Sorteo |> order_by(desc: :inserted_at) |> Repo.all()
  end

  @doc """
  Breve: list_sorteos_futuros.
  """
  def list_sorteos_futuros do
    Repo.all(from s in Sorteo, where: s.estado == "activo", order_by: [asc: :inserted_at])
  end

  @doc """
  Breve: list_sorteos_pasados.
  """
  def list_sorteos_pasados do
    Repo.all(from s in Sorteo, where: s.estado in ["finalizado", "cancelado"], order_by: [desc: :inserted_at])
  end

  @doc """
  Breve: list_sorteos_disponibles.
  """
  def list_sorteos_disponibles do
    Repo.all(from s in Sorteo, where: s.estado == "activo")
  end

  @doc """
  Breve: comprar_ticket.
  """
  def comprar_ticket(usuario, sorteo, numero_ticket) do
    if sorteo.estado != "activo" do
      {:error, "Este sorteo ya no acepta compras"}
    else
      Ecto.Multi.new()
      |> Ecto.Multi.run(:usuario, fn repo, _ ->
        case repo.one(
               from u in Cuentas.Usuario,
               where: u.id == ^usuario.id,
               lock: "FOR UPDATE"
             ) do
          nil -> {:error, "Usuario no encontrado"}
          u -> {:ok, u}
        end
      end)
      |> Ecto.Multi.run(:ticket, fn repo, _ ->
        query =
          from t in Ticket,
            where:
              t.sorteo_id == ^sorteo.id and
                t.numero == ^to_string(numero_ticket) and
                t.estado == "disponible",
            lock: "FOR UPDATE"

        case repo.one(query) do
          nil -> {:error, "El ticket #{numero_ticket} ya fue vendido o no existe"}
          t -> {:ok, t}
        end
      end)
      |> Ecto.Multi.run(:cobro, fn _repo, %{usuario: u} ->
        precio = decimal_seguro(sorteo.precio_ticket)
        saldo_actual = decimal_seguro(u.saldo_virtual)

        if Decimal.compare(saldo_actual, precio) in [:gt, :eq] do
          nuevo_saldo = Decimal.sub(saldo_actual, precio)
          nuevo_gastado = Decimal.add(decimal_seguro(u.total_gastado), precio)

          Cuentas.actualizar_usuario(u, %{
            saldo_virtual: nuevo_saldo,
            total_gastado: nuevo_gastado
          })
        else
          {:error, "Saldo insuficiente. Necesitas $#{precio}"}
        end
      end)
      |> Ecto.Multi.run(:asignar_ticket, fn repo, %{ticket: t, usuario: u} ->
        repo.update(
          Ticket.changeset(t, %{
            usuario_id: u.id,
            estado: "vendido"
          })
        )
      end)
      |> Ecto.Multi.run(:registrar_transaccion, fn _repo, %{usuario: u, ticket: t} ->
        AzarApp.Cuentas.registrar_compra_ticket(
          u.id,
          sorteo.id,
          t.numero,
          sorteo.precio_ticket
        )
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{asignar_ticket: ticket}} ->
          AzarApp.Auditoria.log(:ticket_comprado, %{
            usuario_id: usuario.id,
            sorteo_id: sorteo.id,
            numero: ticket.numero,
            monto: sorteo.precio_ticket
          })
          Phoenix.PubSub.broadcast(AzarApp.PubSub, "sorteo:#{sorteo.id}", :ticket_comprado)
          Phoenix.PubSub.broadcast(AzarApp.PubSub, "sorteos", :lista_actualizada)
          {:ok, ticket}

        {:error, _op, razon, _} ->
          {:error, razon}
      end
    end
  end

  @doc """
  Breve: list_tickets_por_usuario.
  """
  def list_tickets_por_usuario(usuario_id) do
    Repo.all(from t in Ticket, where: t.usuario_id == ^usuario_id, preload: [:sorteo], order_by: [desc: t.inserted_at])
  end

  @doc """
  Breve: recaudo_actual.
  """
  def recaudo_actual(sorteo) do
    vendidos = tickets_vendidos_count(sorteo)
    precio = decimal_seguro(sorteo.precio_ticket)
    Decimal.mult(Decimal.new(vendidos), precio)
  end

  @doc """
  Breve: tickets_vendidos_count.
  """
  def tickets_vendidos_count(sorteo) do
    Repo.aggregate(from(t in Ticket, where: t.sorteo_id == ^sorteo.id and t.estado == "vendido"), :count, :id) || 0
  end

  @doc """
  Breve: premio_actual.
  """
  def premio_actual(sorteo) do
    if sorteo.tipo_premio == "fijo" do
      decimal_seguro(sorteo.premio_fijo)
    else
      recaudo = recaudo_actual(sorteo)
      porcentaje_publico = Decimal.div(Decimal.new(100 - (sorteo.porcentaje_casa || 30)), Decimal.new(100))
      Decimal.mult(recaudo, porcentaje_publico) |> Decimal.round(0)
    end
  end

  @doc """
  Breve: puede_jugar_ahora.
  """
  def puede_jugar_ahora?(sorteo) do
    if sorteo.estado != "activo" do
      false
    else
      vendidos = tickets_vendidos_count(sorteo)

      if sorteo.tipo_premio == "fijo" do
        Decimal.compare(recaudo_actual(sorteo), decimal_seguro(sorteo.premio_fijo)) in [:gt, :eq]
      else
        vendidos > 0
      end
    end
  end

  @doc """
  Breve: razon_no_puede_jugar.
  """
  def razon_no_puede_jugar(sorteo) do
    cond do
      sorteo.estado != "activo" ->
        "El sorteo no está activo"
      sorteo.tipo_premio == "fijo" ->
        falta = Decimal.sub(decimal_seguro(sorteo.premio_fijo), recaudo_actual(sorteo))
        if Decimal.compare(falta, 0) == :gt, do: "Faltan $#{falta} en ventas para cubrir el premio fijo", else: nil
      sorteo.tipo_premio == "acumulado" and tickets_vendidos_count(sorteo) == 0 ->
        "No se han vendido tickets aún"
      true -> nil
    end
  end

  @doc """
  Breve: realizar_sorteo.
  """
  def realizar_sorteo!(sorteo) do
    cond do
      sorteo.estado != "activo" -> {:error, "El sorteo no está activo"}
      not puede_jugar_ahora?(sorteo) -> {:error, razon_no_puede_jugar(sorteo)}
      true ->
        tickets_vendidos = Repo.all(from t in Ticket, where: t.sorteo_id == ^sorteo.id and t.estado == "vendido", preload: [:usuario])

        cantidad_real = min(sorteo.cantidad_ganadores || 1, length(tickets_vendidos))
        ganadores = Enum.take(Enum.shuffle(tickets_vendidos), cantidad_real)
        premio_por_ganador = calcular_premio_dividido(premio_actual(sorteo), cantidad_real)

        resultado = Ecto.Multi.new()
        |> Ecto.Multi.update(:sorteo, Sorteo.changeset(sorteo, %{estado: "finalizado", numeros_ganadores: Enum.map(ganadores, & &1.numero)}))
        |> pagar_ganadores_multi(ganadores, premio_por_ganador)
        |> Repo.transaction()

        case resultado do
          {:ok, %{sorteo: sorteo_actualizado}} ->
            AzarApp.Auditoria.log(:sorteo_ejecutado, %{
              sorteo_id: sorteo_actualizado.id,
              titulo: sorteo_actualizado.titulo,
              ganadores: sorteo_actualizado.numeros_ganadores,
              premio: premio_por_ganador
            })
            notificar_ganadores(ganadores, sorteo_actualizado, premio_por_ganador)
            Phoenix.PubSub.broadcast(AzarApp.PubSub, "sorteo:#{sorteo_actualizado.id}", :sorteo_ejecutado)
            Phoenix.PubSub.broadcast(AzarApp.PubSub, "sorteos", :lista_actualizada)
            {:ok, sorteo_actualizado}
          {:error, _op, razon, _} -> {:error, razon}
        end
    end
  end

  @doc """
  Breve: cancelar_sorteo.
  """
  def cancelar_sorteo(sorteo, motivo \\ "Condiciones mínimas no alcanzadas") do
    if sorteo.estado != "activo" do
      {:error, "Solo se pueden cancelar sorteos activos"}
    else
      tickets_con_dueno = Repo.all(from t in Ticket, where: t.sorteo_id == ^sorteo.id and t.estado == "vendido", preload: [:usuario])

      Ecto.Multi.new()
      |> Ecto.Multi.update(:sorteo, Sorteo.changeset(sorteo, %{estado: "cancelado"}))
      |> reembolsar_compradores_multi(tickets_con_dueno, decimal_seguro(sorteo.precio_ticket))
      |> Repo.transaction()
      |> case do
        {:ok, %{sorteo: sorteo_cancelado}} ->
          AzarApp.Auditoria.log(:sorteo_cancelado, %{
            sorteo_id: sorteo_cancelado.id,
            titulo: sorteo_cancelado.titulo,
            motivo: motivo
          })
          {:ok, sorteo_cancelado}
        {:error, _op, razon, _} -> {:error, razon}
      end
    end
  end

  @doc """
  Breve: verificar_y_cancelar_expirados.
  """
  def verificar_y_cancelar_expirados do
    # Ajuste de zona horaria para Colombia (UTC-5)
    ahora_colombia = NaiveDateTime.utc_now() |> NaiveDateTime.add(-5, :hour)
    sorteos_vencidos = Repo.all(from s in Sorteo, where: s.estado == "activo" and not is_nil(s.fecha_ejecucion) and s.fecha_ejecucion <= ^ahora_colombia)

    Enum.each(sorteos_vencidos, fn sorteo ->
      if puede_jugar_ahora?(sorteo) do
        realizar_sorteo!(sorteo)
      else
        cancelar_sorteo(sorteo, razon_no_puede_jugar(sorteo) || "Fecha vencida")
      end
    end)
    {:ok, length(sorteos_vencidos)}
  end

  @doc """
  Breve: create_sorteo.
  """
  def create_sorteo(attrs \\ %{}) do
    case Repo.transaction(fn ->
      case %Sorteo{} |> Sorteo.changeset(attrs) |> Repo.insert() do
        {:ok, sorteo} ->
          AzarApp.Auditoria.log(:sorteo_creado, %{
            sorteo_id: sorteo.id,
            titulo: sorteo.titulo,
            tipo: sorteo.tipo_premio
          })

          ahora = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          tickets = Enum.map(1..sorteo.total_tickets, fn num ->
            %{sorteo_id: sorteo.id, numero: to_string(num), estado: "disponible", inserted_at: ahora, updated_at: ahora}
          end)
          Repo.insert_all(Ticket, tickets)
          sorteo
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end) do
      {:ok, sorteo} ->
        Phoenix.PubSub.broadcast(AzarApp.PubSub, "sorteos", {:sorteo_creado, sorteo})
        {:ok, sorteo}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Breve: update_sorteo.
  """
  def update_sorteo(s, attrs), do: s |> Sorteo.changeset(attrs) |> Repo.update()
  @doc """
  Breve: delete_sorteo.
  """
  def delete_sorteo(s) do
    case Repo.delete(s) do
      {:ok, sorteo} ->
        AzarApp.Auditoria.log(:sorteo_eliminado, %{
          sorteo_id: s.id,
          titulo: s.titulo
        })
        Phoenix.PubSub.broadcast(AzarApp.PubSub, "sorteos", {:sorteo_eliminado, sorteo})
        {:ok, sorteo}
      error -> error
    end
  end
  @doc """
  Breve: change_sorteo.
  """
  def change_sorteo(s, attrs \\ %{}), do: Sorteo.changeset(s, attrs)

  defp pagar_ganadores_multi(multi, ganadores, premio_por_ganador) do
    Enum.reduce(ganadores, multi, fn ticket, acc ->
      Ecto.Multi.run(acc, {:pagar, ticket.id}, fn _repo, _ -> Cuentas.registrar_premio(ticket.usuario, premio_por_ganador) end)
    end)
  end

  defp reembolsar_compradores_multi(multi, tickets, precio_ticket) do
    Enum.reduce(tickets, multi, fn ticket, acc ->
      Ecto.Multi.run(acc, {:reembolso, ticket.id}, fn _repo, _ ->
        Cuentas.recargar_saldo(ticket.usuario, precio_ticket)
        AzarApp.Auditoria.log(:devolucion_cancelacion, %{
          usuario_id: ticket.usuario_id,
          sorteo_id: ticket.sorteo_id,
          monto: precio_ticket
        })
      end)
    end)
  end

  defp notificar_ganadores(ganadores, sorteo, premio_por_ganador) do
    Enum.each(ganadores, fn ticket ->
      AzarApp.Auditoria.log(:premio_pagado, %{
        usuario_id: ticket.usuario_id,
        sorteo_id: sorteo.id,
        monto: premio_por_ganador
      })

      case AzarApp.Notificaciones.crear_notificacion_premio(ticket.usuario_id, sorteo, ticket.numero, premio_por_ganador) do
        {:ok, notif} -> Phoenix.PubSub.broadcast(AzarApp.PubSub, "usuario:#{ticket.usuario_id}", {:premio_ganado, Repo.preload(notif, :sorteo)})
        {:error, _} -> :ok
      end
    end)
  end

  @doc """
  Breve: devolver_ticket.
  """
  def devolver_ticket(usuario, ticket_id) do
    ticket = Repo.get!(Ticket, ticket_id) |> Repo.preload(:sorteo)

    cond do
      ticket.usuario_id != usuario.id ->
        {:error, "Este ticket no te pertenece"}

      ticket.estado != "vendido" ->
        {:error, "Este ticket no está vendido"}

      ticket.sorteo.estado != "activo" ->
        {:error, "No se puede devolver: el sorteo ya fue #{ticket.sorteo.estado}"}

      true ->
        precio = decimal_seguro(ticket.sorteo.precio_ticket)

        Ecto.Multi.new()
        |> Ecto.Multi.update(:ticket, Ticket.changeset(ticket, %{estado: "disponible", usuario_id: nil}))
        |> Ecto.Multi.run(:reembolso, fn _repo, _ ->
            usuario_fresco = Cuentas.obtener_usuario!(usuario.id)
            nuevo_saldo   = Decimal.add(decimal_seguro(usuario_fresco.saldo_virtual), precio)
            nuevo_gastado = Decimal.sub(decimal_seguro(usuario_fresco.total_gastado), precio)

            Cuentas.actualizar_usuario(usuario_fresco, %{
              saldo_virtual: nuevo_saldo,
              total_gastado: nuevo_gastado
            })
          end)
        |> Ecto.Multi.run(:transaccion, fn _repo, _ ->
            Cuentas.registrar_devolucion_ticket(usuario.id, ticket.sorteo_id, ticket.numero, precio)
          end)
        |> Repo.transaction()
        |> case do
            {:ok, _} ->
              AzarApp.Auditoria.log(:ticket_devuelto, %{
                usuario_id: usuario.id,
                sorteo_id: ticket.sorteo_id,
                numero: ticket.numero,
                monto: precio
              })
              Phoenix.PubSub.broadcast(AzarApp.PubSub, "sorteo:#{ticket.sorteo_id}", :ticket_comprado)
              {:ok, ticket}
            {:error, _, razon, _} -> {:error, razon}
          end
    end
  end

  defp decimal_seguro(nil), do: Decimal.new(0)
  defp decimal_seguro(%Decimal{} = val), do: val
  defp decimal_seguro(val) when is_binary(val) or is_integer(val) or is_float(val), do: Decimal.new(to_string(val))

  defp calcular_premio_dividido(total, cantidad) when cantidad > 1, do: Decimal.div(total, Decimal.new(cantidad)) |> Decimal.round(0)
  defp calcular_premio_dividido(total, _), do: total
end
