defmodule AzarApp.Sorteos.Sorteo do
  @moduledoc """
  Módulo AzarApp.Sorteos.Sorteo: lógica relacionada con sorteo.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "sorteos" do
    field :titulo, :string
    field :descripcion, :string
    field :precio_ticket, :decimal
    field :total_tickets, :integer
    field :cantidad_ganadores, :integer, default: 1
    field :tipo_premio, :string, default: "acumulado"
    field :premio_fijo, :decimal
    field :porcentaje_casa, :integer, default: 30
    field :estado, :string, default: "activo"
    field :numeros_ganadores, {:array, :string}, default: []
    field :fecha_ejecucion, :naive_datetime

    has_many :tickets, AzarApp.Sorteos.Ticket

    timestamps()
  end

  @doc false
  def changeset(sorteo, attrs) do
    sorteo
    |> cast(attrs, [
      :titulo,
      :descripcion,
      :precio_ticket,
      :total_tickets,
      :cantidad_ganadores,
      :tipo_premio,
      :premio_fijo,
      :porcentaje_casa,
      :estado,
      :numeros_ganadores,
      :fecha_ejecucion
    ])
    |> validate_required([:titulo, :precio_ticket, :total_tickets, :tipo_premio])
    |> validate_number(:precio_ticket, greater_than: 0,
        message: "El precio del ticket debe ser mayor a 0")
    |> validate_number(:total_tickets, greater_than: 0, less_than_or_equal_to: 1_000_000,
        message: "El total de tickets debe estar entre 1 y 1.000.000")
    |> validate_number(:cantidad_ganadores, greater_than: 0,
        message: "Debe haber al menos 1 ganador")
    |> validate_inclusion(:tipo_premio, ["acumulado", "fijo"],
        message: "Tipo de sorteo inválido")
    |> validate_fecha_futura()
    |> validate_ganadores_vs_tickets()
    |> validate_tipo_fijo()
    |> validate_porcentaje_casa()
  end


  defp validate_fecha_futura(changeset) do
    case get_change(changeset, :fecha_ejecucion) do
      nil ->
        changeset

      fecha ->
        if NaiveDateTime.compare(fecha, NaiveDateTime.utc_now()) == :lt do
          add_error(changeset, :fecha_ejecucion, "La fecha del sorteo debe ser en el futuro")
        else
          changeset
        end
    end
  end

  defp validate_ganadores_vs_tickets(changeset) do
    ganadores = get_field(changeset, :cantidad_ganadores)
    tickets = get_field(changeset, :total_tickets)

    if ganadores && tickets && ganadores >= tickets do
      add_error(changeset, :cantidad_ganadores,
        "La cantidad de ganadores debe ser menor al total de tickets")
    else
      changeset
    end
  end

  defp validate_tipo_fijo(changeset) do
    if get_field(changeset, :tipo_premio) == "fijo" do
      changeset
      |> validate_required([:premio_fijo], message: "El premio fijo es requerido")
      |> validate_number(:premio_fijo, greater_than: 0,
          message: "El premio fijo debe ser mayor a 0")
      |> validate_recaudo_doble_del_premio()
    else
      changeset
    end
  end

  defp validate_recaudo_doble_del_premio(changeset) do
    total = get_field(changeset, :total_tickets)
    precio = get_field(changeset, :precio_ticket)
    premio = get_field(changeset, :premio_fijo)

    with true <- not is_nil(total),
         true <- not is_nil(precio),
         true <- not is_nil(premio),
         {:ok, precio_d} <- Decimal.cast(precio),
         {:ok, premio_d} <- Decimal.cast(premio) do
      recaudo_maximo = Decimal.mult(Decimal.new(total), precio_d)
      minimo_requerido = Decimal.mult(premio_d, Decimal.new(2))

      if Decimal.compare(recaudo_maximo, minimo_requerido) == :lt do
        add_error(
          changeset,
          :premio_fijo,
          "El recaudo máximo ($#{recaudo_maximo}) debe ser al menos el doble del premio ($#{minimo_requerido}). Reduce el premio o aumenta tickets/precio."
        )
      else
        changeset
      end
    else
      _ -> changeset
    end
  end

  defp validate_porcentaje_casa(changeset) do
    if get_field(changeset, :tipo_premio) == "acumulado" do
      changeset
      |> validate_required([:porcentaje_casa], message: "El % de comisión es requerido")
      |> validate_number(:porcentaje_casa,
          greater_than: 0, less_than: 100,
          message: "El porcentaje de la casa debe estar entre 1 y 99")
    else
      changeset
    end
  end
end
