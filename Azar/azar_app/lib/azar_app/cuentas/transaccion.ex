defmodule AzarApp.Cuentas.Transaccion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transacciones" do
    field :tipo, :string
    field :monto, :decimal
    field :descripcion, :string
    field :ticket_numero, :string

    belongs_to :usuario, AzarApp.Cuentas.Usuario
    belongs_to :sorteo, AzarApp.Sorteos.Sorteo

    timestamps(type: :utc_datetime)
  end

  def changeset(transaccion, attrs) do
    transaccion
    |> cast(attrs, [:tipo, :monto, :descripcion, :usuario_id, :sorteo_id, :ticket_numero])
    |> validate_required([:tipo, :monto, :usuario_id])
    |> validate_inclusion(:tipo, ["recarga", "compra_ticket", "devolucion_ticket", "premio"])
  end
end
