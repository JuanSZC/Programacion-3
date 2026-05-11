defmodule AzarApp.Sorteos do
  import Ecto.Query, warn: false
  alias AzarApp.Repo
  alias AzarApp.Sorteos.Sorteo
  alias AzarApp.Sorteos.Ticket
  alias AzarApp.Cuentas

  # --- LECTURA DE SORTEOS ---

  def get_sorteo!(id), do: Repo.get!(Sorteo, id) |> Repo.preload([:tickets])

  def get_sorteo_con_tickets!(id) do
    Sorteo
    |> Repo.get!(id)
    |> Repo.preload(tickets: [:usuario])
  end

  def list_sorteos do
    Sorteo
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def list_sorteos_disponibles do
    Repo.all(from s in Sorteo, where: s.estado == "activo")
  end

  def list_sorteos_futuros do
    ahora = DateTime.utc_now()
    Repo.all(
      from s in Sorteo,
      where: s.fecha_ejecucion >= ^ahora,
      order_by: [asc: s.fecha_ejecucion]
    )
  end

  def list_sorteos_pasados do
    ahora = DateTime.utc_now()
    Repo.all(
      from s in Sorteo,
      where: s.fecha_ejecucion < ^ahora,
      order_by: [desc: s.fecha_ejecucion]
    )
  end

  # --- GESTIÓN DE TICKETS ---

  def listar_tickets_del_sorteo(sorteo_id) do
    Repo.all(from t in Ticket, where: t.sorteo_id == ^sorteo_id)
  end

  def comprar_ticket(usuario, sorteo, numero_ticket) do
    Repo.transaction(fn ->
      # CORRECCIÓN ARITMÉTICA: Usar Decimal.sub para evitar ArithmeticError
      nuevo_saldo = Decimal.sub(usuario.saldo_virtual, sorteo.precio_ticket)

      # 1. Actualizar saldo del usuario
      case Cuentas.actualizar_usuario(usuario, %{saldo_virtual: nuevo_saldo}) do
        {:ok, _} -> :ok
        {:error, changeset} -> Repo.rollback(changeset)
      end

      # 2. Buscar el ticket por número (como String)
      ticket = Repo.get_by!(Ticket,
        sorteo_id: sorteo.id,
        numero: "#{numero_ticket}"
      )

      # 3. Actualizar ticket a "vendido"
      case Repo.update(Ticket.changeset(ticket, %{
        usuario_id: usuario.id,
        estado: "vendido"
      })) do
        {:ok, ticket_actualizado} -> ticket_actualizado
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  # --- CREACIÓN Y MODIFICACIÓN ---

  def create_sorteo(attrs \\ %{}) do
    Repo.transaction(fn ->
      case %Sorteo{} |> Sorteo.changeset(attrs) |> Repo.insert() do
        {:ok, sorteo} ->
          generar_tickets_bulk(sorteo)
          sorteo
        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp generar_tickets_bulk(sorteo) do
    ahora = DateTime.utc_now() |> DateTime.truncate(:second)

    tickets = Enum.map(1..sorteo.total_tickets, fn n ->
      %{
        sorteo_id: sorteo.id,
        numero: Integer.to_string(n),
        estado: "disponible",
        inserted_at: ahora,
        updated_at: ahora
      }
    end)

    Repo.insert_all(Ticket, tickets)
  end

  def update_sorteo(%Sorteo{} = sorteo, attrs) do
    sorteo
    |> Sorteo.changeset(attrs)
    |> Repo.update()
  end

  def delete_sorteo(sorteo), do: Repo.delete(sorteo)

  def change_sorteo(sorteo, attrs \\ %{}), do: Sorteo.changeset(sorteo, attrs)
end
