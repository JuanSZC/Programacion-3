defmodule AzarApp.Sorteos.Sorteo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sorteos" do
    field :titulo, :string
    field :descripcion, :string
    field :precio_ticket, :decimal
    field :fecha_ejecucion, :utc_datetime
    field :total_tickets, :integer, default: 100
    field :cantidad_ganadores, :integer, default: 1
    field :estado, :string, default: "activo"

    has_many :tickets, AzarApp.Sorteos.Ticket

    timestamps()
  end

  def changeset(sorteo, attrs) do
    sorteo
    |> cast(attrs, [:titulo, :descripcion, :precio_ticket, :fecha_ejecucion, :total_tickets, :cantidad_ganadores, :estado])
    |> validate_required([:titulo, :precio_ticket, :fecha_ejecucion, :total_tickets, :cantidad_ganadores])
    # 1. Validar que no sean negativos y tengan un tope razonable para evitar el error de Postgrex
    |> validate_number(:total_tickets, greater_than: 0, less_than: 1_000_000)
    |> validate_number(:cantidad_ganadores, greater_than: 0)
    |> validate_number(:precio_ticket, greater_than: 0)
    # 2. Validar que la fecha no sea en el pasado
    |> validate_fecha_futura()
    # 3. Validar la regla del 25% de ganadores
    |> validate_porcentaje_ganadores()
  end

  defp validate_fecha_futura(changeset) do
    fecha = get_field(changeset, :fecha_ejecucion)
    if fecha && DateTime.compare(fecha, DateTime.utc_now()) == :lt do
      add_error(changeset, :fecha_ejecucion, "no puede ser una fecha pasada")
    else
      changeset
    end
  end

  defp validate_porcentaje_ganadores(changeset) do
    tickets = get_field(changeset, :total_tickets) || 0
    ganadores = get_field(changeset, :cantidad_ganadores) || 0

    if ganadores > (tickets * 0.25) do
      add_error(changeset, :cantidad_ganadores, "no puede superar el 25% de los tickets totales (máx: #{round(tickets * 0.25)})")
    else
      changeset
    end
  end
end
