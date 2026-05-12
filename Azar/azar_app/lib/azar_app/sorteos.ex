defmodule AzarApp.Sorteos do
  import Ecto.Query, warn: false
  alias AzarApp.Repo
  alias AzarApp.Sorteos.Sorteo
  alias AzarApp.Sorteos.Ticket
  alias AzarApp.Cuentas

  # ---------------------------------------------------------------------------
  # LECTURA DE SORTEOS
  # ---------------------------------------------------------------------------

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
    Repo.all(
      from s in Sorteo,
      where: s.estado in ["finalizado", "cancelado"],
      order_by: [desc: :inserted_at]
    )
  end

  def list_sorteos_disponibles do
    Repo.all(from s in Sorteo, where: s.estado == "activo")
  end

  # ---------------------------------------------------------------------------
  # GESTIÓN DE TICKETS
  # ---------------------------------------------------------------------------

  def comprar_ticket(usuario, sorteo, numero_ticket) do
    # Guarda de seguridad: no permitir compra si el sorteo ya no está activo
    if sorteo.estado != "activo" do
      {:error, "Este sorteo ya no acepta compras"}
    else
      Ecto.Multi.new()
      |> Ecto.Multi.run(:usuario, fn repo, _ ->
        query = from u in AzarApp.Cuentas.Usuario, where: u.id == ^usuario.id, lock: "FOR UPDATE"
        case repo.one(query) do
          nil -> {:error, "Usuario no encontrado"}
          u -> {:ok, u}
        end
      end)
      |> Ecto.Multi.run(:ticket, fn repo, _ ->
        query =
          from t in Ticket,
            where:
              t.sorteo_id == ^sorteo.id and
                t.numero == ^"#{numero_ticket}" and
                t.estado == "disponible",
            lock: "FOR UPDATE"

        case repo.one(query) do
          nil -> {:error, "El ticket #{numero_ticket} ya fue vendido"}
          t -> {:ok, t}
        end
      end)
      |> Ecto.Multi.run(:cobro, fn _repo, %{usuario: u} ->
        precio = sorteo.precio_ticket
        saldo_actual = u.saldo_virtual || Decimal.new("0")

        if Decimal.compare(saldo_actual, precio) in [:gt, :eq] do
          nuevo_saldo = Decimal.sub(saldo_actual, precio)
          nuevo_gastado = Decimal.add(u.total_gastado || Decimal.new("0"), precio)

          Cuentas.actualizar_usuario(u, %{
            saldo_virtual: nuevo_saldo,
            total_gastado: nuevo_gastado
          })
        else
          {:error, "Saldo insuficiente"}
        end
      end)
      |> Ecto.Multi.run(:asignar_ticket, fn repo, %{ticket: t, usuario: u} ->
        repo.update(Ticket.changeset(t, %{usuario_id: u.id, estado: "vendido"}))
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{asignar_ticket: ticket}} -> {:ok, ticket}
        {:error, _op, razon, _} -> {:error, razon}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # LÓGICA DE CASINO
  # ---------------------------------------------------------------------------

  def recaudo_actual(sorteo) do
    tickets_vendidos =
      Repo.aggregate(
        from(t in Ticket, where: t.sorteo_id == ^sorteo.id and t.estado == "vendido"),
        :count,
        :id
      )

    precio =
      case Decimal.cast(sorteo.precio_ticket) do
        {:ok, p} -> p
        _ -> Decimal.new(0)
      end

    Decimal.mult(Decimal.new(tickets_vendidos), precio)
  end

  def tickets_vendidos_count(sorteo) do
    Repo.aggregate(
      from(t in Ticket, where: t.sorteo_id == ^sorteo.id and t.estado == "vendido"),
      :count,
      :id
    )
  end

  def premio_actual(sorteo) do
    if sorteo.tipo_premio == "fijo" do
      case Decimal.cast(sorteo.premio_fijo || 0) do
        {:ok, p} -> p
        _ -> Decimal.new(0)
      end
    else
      recaudo = recaudo_actual(sorteo)
      porcentaje_publico =
        Decimal.new(100 - (sorteo.porcentaje_casa || 30)) |> Decimal.div(Decimal.new(100))

      Decimal.mult(recaudo, porcentaje_publico) |> Decimal.round(0)
    end
  end

  @doc """
  Determina si un sorteo puede ejecutarse ahora mismo.

  Reglas:
  - FIJO: el recaudo acumulado debe ser >= al premio fijo (casa cubre el premio).
  - ACUMULADO: debe haber al menos 1 ticket vendido (premio > 0).
  - En ambos casos el sorteo debe estar en estado "activo".
  """
  def puede_jugar_ahora?(sorteo) do
    if sorteo.estado != "activo" do
      false
    else
      vendidos = tickets_vendidos_count(sorteo)

      if sorteo.tipo_premio == "fijo" do
        premio =
          case Decimal.cast(sorteo.premio_fijo || 0) do
            {:ok, p} -> p
            _ -> Decimal.new(0)
          end

        recaudo = recaudo_actual(sorteo)
        # El recaudo debe cubrir al menos el premio para poder jugarse
        Decimal.compare(recaudo, premio) in [:gt, :eq]
      else
        # Acumulado: no tiene sentido jugar con premio $0
        vendidos > 0
      end
    end
  end

  @doc """
  Motivo por el que un sorteo no puede jugarse todavía.
  Útil para mostrar mensajes descriptivos en la UI.
  """
  def razon_no_puede_jugar(sorteo) do
    cond do
      sorteo.estado != "activo" ->
        "El sorteo no está activo"

      sorteo.tipo_premio == "fijo" ->
        recaudo = recaudo_actual(sorteo)
        premio = Decimal.cast(sorteo.premio_fijo || 0) |> elem(1)
        falta = Decimal.sub(premio, recaudo)

        if Decimal.compare(falta, 0) == :gt do
          "Faltan $#{falta} en ventas para cubrir el premio fijo"
        else
          nil
        end

      sorteo.tipo_premio == "acumulado" ->
        if tickets_vendidos_count(sorteo) == 0 do
          "No se han vendido tickets aún (premio acumulado es $0)"
        else
          nil
        end

      true ->
        nil
    end
  end

  @doc """
  Realiza el sorteo eligiendo ganador(es) aleatoriamente y pagando el premio.
  """
   @doc """
  Realiza el sorteo, paga el premio y notifica al ganador en tiempo real
  (o guarda la notificación para cuando se conecte).
  """
  def realizar_sorteo!(sorteo) do
    cond do
      sorteo.estado != "activo" ->
        {:error, "El sorteo no está activo"}

      not puede_jugar_ahora?(sorteo) ->
        {:error, razon_no_puede_jugar(sorteo)}

      true ->
        tickets_vendidos =
          Ticket
          |> where([t], t.sorteo_id == ^sorteo.id and t.estado == "vendido")
          |> preload(:usuario)
          |> Repo.all()

        cantidad_ganadores = sorteo.cantidad_ganadores || 1
        cantidad_real = min(cantidad_ganadores, length(tickets_vendidos))
        ganadores = tickets_vendidos |> Enum.shuffle() |> Enum.take(cantidad_real)
        numeros_ganadores = Enum.map(ganadores, & &1.numero)
        premio_total = premio_actual(sorteo)

        premio_por_ganador =
          if cantidad_real > 1 do
            Decimal.div(premio_total, Decimal.new(cantidad_real)) |> Decimal.round(0)
          else
            premio_total
          end

        resultado =
          Ecto.Multi.new()
          |> Ecto.Multi.update(
            :sorteo,
            Sorteo.changeset(sorteo, %{
              estado: "finalizado",
              numeros_ganadores: numeros_ganadores
            })
          )
          |> pagar_ganadores_multi(ganadores, premio_por_ganador)
          |> Repo.transaction()

        case resultado do
          {:ok, %{sorteo: sorteo_actualizado}} ->
            # Notificamos FUERA de la transacción para no bloquearla
            notificar_ganadores(ganadores, sorteo_actualizado, premio_por_ganador)
            {:ok, sorteo_actualizado}

          {:error, _op, razon, _} ->
            {:error, razon}
        end
    end
  end

  # Crea la notificación en BD y hace broadcast PubSub a cada ganador
  defp notificar_ganadores(ganadores, sorteo, premio_por_ganador) do
    alias AzarApp.Notificaciones
    alias Phoenix.PubSub

    Enum.each(ganadores, fn ticket ->
      case Notificaciones.crear_notificacion_premio(
             ticket.usuario_id,
             sorteo,
             ticket.numero,
             premio_por_ganador
           ) do
        {:ok, notificacion} ->
          # Precargamos el sorteo para que el modal tenga el título disponible
          notificacion_completa = Repo.preload(notificacion, :sorteo)

          PubSub.broadcast(
            AzarApp.PubSub,
            "usuario:#{ticket.usuario_id}",
            {:premio_ganado, notificacion_completa}
          )

        {:error, razon} ->
          IO.puts("[Sorteos] Error al crear notificación para usuario #{ticket.usuario_id}: #{inspect(razon)}")
      end
    end)
  end


  @doc """
  Cancela un sorteo y devuelve el saldo a todos los compradores.
  Se usa cuando expira la fecha sin cumplir las condiciones mínimas.
  """
  def cancelar_sorteo(sorteo, motivo \\ "Condiciones mínimas no alcanzadas") do
    if sorteo.estado != "activo" do
      {:error, "Solo se pueden cancelar sorteos activos"}
    else
      tickets_con_dueno =
        Ticket
        |> where([t], t.sorteo_id == ^sorteo.id and t.estado == "vendido")
        |> preload(:usuario)
        |> Repo.all()

      Ecto.Multi.new()
      |> Ecto.Multi.update(
        :sorteo,
        Sorteo.changeset(sorteo, %{estado: "cancelado"})
      )
      |> reembolsar_compradores_multi(tickets_con_dueno, sorteo.precio_ticket)
      |> Repo.transaction()
      |> case do
        {:ok, %{sorteo: sorteo_cancelado}} ->
          IO.puts("[Sorteos] Sorteo ##{sorteo.id} cancelado: #{motivo}. #{length(tickets_con_dueno)} reembolsos procesados.")
          {:ok, sorteo_cancelado}

        {:error, _op, razon, _} ->
          {:error, razon}
      end
    end
  end

  @doc """
  Revisa todos los sorteos activos con fecha vencida y los cancela si no
  cumplen las condiciones mínimas para ejecutarse.
  Llamado periódicamente por el Scheduler.
  """
  def verificar_y_cancelar_expirados do
    ahora = NaiveDateTime.utc_now()

    sorteos_vencidos =
      Repo.all(
        from s in Sorteo,
          where: s.estado == "activo" and not is_nil(s.fecha_ejecucion) and s.fecha_ejecucion <= ^ahora
      )

    Enum.each(sorteos_vencidos, fn sorteo ->
      if puede_jugar_ahora?(sorteo) do
        # Tiene condiciones, lo ejecutamos automáticamente
        case realizar_sorteo!(sorteo) do
          {:ok, _} ->
            IO.puts("[Sorteos] Sorteo ##{sorteo.id} ejecutado automáticamente al vencer la fecha.")
          {:error, razon} ->
            IO.puts("[Sorteos] Error al ejecutar sorteo ##{sorteo.id}: #{razon}")
        end
      else
        # No cumple condiciones → cancelar con reembolso
        motivo = razon_no_puede_jugar(sorteo) || "Fecha vencida sin condiciones mínimas"
        cancelar_sorteo(sorteo, motivo)
      end
    end)

    {:ok, length(sorteos_vencidos)}
  end

  # ---------------------------------------------------------------------------
  # CRUD
  # ---------------------------------------------------------------------------

  def create_sorteo(attrs \\ %{}) do
    Repo.transaction(fn ->
      case %Sorteo{} |> Sorteo.changeset(attrs) |> Repo.insert() do
        {:ok, sorteo} ->
          ahora = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

          tickets =
            Enum.map(1..sorteo.total_tickets, fn numero ->
              %{
                sorteo_id: sorteo.id,
                numero: Integer.to_string(numero),
                estado: "disponible",
                inserted_at: ahora,
                updated_at: ahora
              }
            end)

          Repo.insert_all(Ticket, tickets)
          sorteo

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def update_sorteo(s, attrs), do: s |> Sorteo.changeset(attrs) |> Repo.update()
  def delete_sorteo(s), do: Repo.delete(s)
  def change_sorteo(s, attrs \\ %{}), do: Sorteo.changeset(s, attrs)

  # ---------------------------------------------------------------------------
  # HELPERS PRIVADOS
  # ---------------------------------------------------------------------------

  # Agrega pasos al Multi para pagar a cada ganador
  defp pagar_ganadores_multi(multi, ganadores, premio_por_ganador) do
    Enum.reduce(ganadores, multi, fn ticket, acc ->
      Ecto.Multi.run(acc, {:pagar, ticket.id}, fn _repo, _changes ->
        Cuentas.registrar_premio(ticket.usuario, premio_por_ganador)
      end)
    end)
  end

  # Agrega pasos al Multi para reembolsar a cada comprador
  defp reembolsar_compradores_multi(multi, tickets, precio_ticket) do
    Enum.reduce(tickets, multi, fn ticket, acc ->
      Ecto.Multi.run(acc, {:reembolso, ticket.id}, fn _repo, _changes ->
        Cuentas.recargar_saldo(ticket.usuario, precio_ticket)
      end)
    end)
  end
end
