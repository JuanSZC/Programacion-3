defmodule AzarApp.Sorteos do
  @moduledoc false

  import Ecto.Query, warn: false
  alias AzarApp.Repo
  alias AzarApp.Sorteos.{Sorteo, Ticket}
  alias AzarApp.Cuentas

  # ==========================================
  # LECTURA DE SORTEOS
  # ==========================================

  def get_sorteo!(id), do: Repo.get!(Sorteo, id) |> Repo.preload([:tickets])

  def get_sorteo_con_tickets!(id) do
    Sorteo
    |> Repo.get!(id)
    |> Repo.preload(tickets: [:usuario])
  end

  def list_sorteos do
    Sorteo |> order_by(desc: :inserted_at) |> Repo.all()
  end

  def list_sorteos_futuros do
    Repo.all(from s in Sorteo, where: s.estado == "activo", order_by: [asc: :inserted_at])
  end

  def list_sorteos_pasados do
    Repo.all(from s in Sorteo, where: s.estado in ["finalizado", "cancelado"], order_by: [desc: :inserted_at])
  end

  def list_sorteos_disponibles do
    Repo.all(from s in Sorteo, where: s.estado == "activo")
  end

  # ==========================================
  # GESTIÓN DE TICKETS Y COMPRAS
  # ==========================================

  # Compra segura usando transacciones y bloqueo de fila (FOR UPDATE)
  def comprar_ticket(usuario, sorteo, numero_ticket) do
    if sorteo.estado != "activo" do
      {:error, "Este sorteo ya no acepta compras"}
    else
      Ecto.Multi.new()
      |> Ecto.Multi.run(:usuario, fn repo, _ ->
        case repo.one(from u in Cuentas.Usuario, where: u.id == ^usuario.id, lock: "FOR UPDATE") do
          nil -> {:error, "Usuario no encontrado"}
          u -> {:ok, u}
        end
      end)
      |> Ecto.Multi.run(:ticket, fn repo, _ ->
        query = from t in Ticket,
          where: t.sorteo_id == ^sorteo.id and t.numero == ^to_string(numero_ticket) and t.estado == "disponible",
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

          Cuentas.actualizar_usuario(u, %{saldo_virtual: nuevo_saldo, total_gastado: nuevo_gastado})
        else
          {:error, "Saldo insuficiente. Necesitas $#{precio}"}
        end
      end)
      |> Ecto.Multi.run(:asignar_ticket, fn repo, %{ticket: t, usuario: u} ->
        repo.update(Ticket.changeset(t, %{usuario_id: u.id, estado: "vendido"}))
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{asignar_ticket: ticket}} ->
          Phoenix.PubSub.broadcast(AzarApp.PubSub, "sorteo:#{sorteo.id}", :ticket_comprado)
          Phoenix.PubSub.broadcast(AzarApp.PubSub, "sorteos", :lista_actualizada)
          {:ok, ticket}

        {:error, _op, razon, _} ->
          {:error, razon}
      end
    end
  end

  def list_tickets_por_usuario(usuario_id) do
    Repo.all(from t in Ticket, where: t.usuario_id == ^usuario_id, preload: [:sorteo], order_by: [desc: t.inserted_at])
  end

  # ==========================================
  # LÓGICA DE CASINO Y SORTEOS
  # ==========================================

  def recaudo_actual(sorteo) do
    vendidos = tickets_vendidos_count(sorteo)
    precio = decimal_seguro(sorteo.precio_ticket)
    Decimal.mult(Decimal.new(vendidos), precio)
  end

  def tickets_vendidos_count(sorteo) do
    Repo.aggregate(from(t in Ticket, where: t.sorteo_id == ^sorteo.id and t.estado == "vendido"), :count, :id) || 0
  end

  def premio_actual(sorteo) do
    if sorteo.tipo_premio == "fijo" do
      decimal_seguro(sorteo.premio_fijo)
    else
      recaudo = recaudo_actual(sorteo)
      porcentaje_publico = Decimal.div(Decimal.new(100 - (sorteo.porcentaje_casa || 30)), Decimal.new(100))
      Decimal.mult(recaudo, porcentaje_publico) |> Decimal.round(0)
    end
  end

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

  # ==========================================
  # EJECUCIÓN Y CANCELACIÓN DE SORTEOS
  # ==========================================

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
            notificar_ganadores(ganadores, sorteo_actualizado, premio_por_ganador)
            Phoenix.PubSub.broadcast(AzarApp.PubSub, "sorteo:#{sorteo_actualizado.id}", :sorteo_ejecutado)
            Phoenix.PubSub.broadcast(AzarApp.PubSub, "sorteos", :lista_actualizada)
            {:ok, sorteo_actualizado}
          {:error, _op, razon, _} -> {:error, razon}
        end
    end
  end

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
          IO.puts("[Sorteos] Sorteo ##{sorteo.id} cancelado: #{motivo}. #{length(tickets_con_dueno)} reembolsos.")
          {:ok, sorteo_cancelado}
        {:error, _op, razon, _} -> {:error, razon}
      end
    end
  end

  def verificar_y_cancelar_expirados do
    ahora = NaiveDateTime.utc_now()
    sorteos_vencidos = Repo.all(from s in Sorteo, where: s.estado == "activo" and not is_nil(s.fecha_ejecucion) and s.fecha_ejecucion <= ^ahora)

    Enum.each(sorteos_vencidos, fn sorteo ->
      if puede_jugar_ahora?(sorteo) do
        realizar_sorteo!(sorteo)
      else
        cancelar_sorteo(sorteo, razon_no_puede_jugar(sorteo) || "Fecha vencida")
      end
    end)
    {:ok, length(sorteos_vencidos)}
  end

  # ==========================================
  # CRUD BÁSICO
  # ==========================================

  def create_sorteo(attrs \\ %{}) do
    case Repo.transaction(fn ->
      case %Sorteo{} |> Sorteo.changeset(attrs) |> Repo.insert() do
        {:ok, sorteo} ->
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

  def update_sorteo(s, attrs), do: s |> Sorteo.changeset(attrs) |> Repo.update()
  def delete_sorteo(s) do
    case Repo.delete(s) do
      {:ok, sorteo} ->
        Phoenix.PubSub.broadcast(AzarApp.PubSub, "sorteos", {:sorteo_eliminado, sorteo})
        {:ok, sorteo}
      error -> error
    end
  end
  def change_sorteo(s, attrs \\ %{}), do: Sorteo.changeset(s, attrs)

  # ==========================================
  # HELPERS PRIVADOS
  # ==========================================

  defp pagar_ganadores_multi(multi, ganadores, premio_por_ganador) do
    Enum.reduce(ganadores, multi, fn ticket, acc ->
      Ecto.Multi.run(acc, {:pagar, ticket.id}, fn _repo, _ -> Cuentas.registrar_premio(ticket.usuario, premio_por_ganador) end)
    end)
  end

  defp reembolsar_compradores_multi(multi, tickets, precio_ticket) do
    Enum.reduce(tickets, multi, fn ticket, acc ->
      Ecto.Multi.run(acc, {:reembolso, ticket.id}, fn _repo, _ -> Cuentas.recargar_saldo(ticket.usuario, precio_ticket) end)
    end)
  end

  defp notificar_ganadores(ganadores, sorteo, premio_por_ganador) do
    Enum.each(ganadores, fn ticket ->
      case AzarApp.Notificaciones.crear_notificacion_premio(ticket.usuario_id, sorteo, ticket.numero, premio_por_ganador) do
        {:ok, notif} -> Phoenix.PubSub.broadcast(AzarApp.PubSub, "usuario:#{ticket.usuario_id}", {:premio_ganado, Repo.preload(notif, :sorteo)})
        {:error, _} -> :ok
      end
    end)
  end

  # Garantiza que el valor devuelto sea siempre una estructura Decimal
  defp decimal_seguro(nil), do: Decimal.new(0)
  defp decimal_seguro(%Decimal{} = val), do: val
  defp decimal_seguro(val) when is_binary(val) or is_integer(val) or is_float(val), do: Decimal.new(to_string(val))

  defp calcular_premio_dividido(total, cantidad) when cantidad > 1, do: Decimal.div(total, Decimal.new(cantidad)) |> Decimal.round(0)
  defp calcular_premio_dividido(total, _), do: total
end
