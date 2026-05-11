defmodule AzarApp.Sorteos.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tickets" do
    field :numero, :string
    field :estado, :string, default: "disponible" # disponible, apartado, pagado

    belongs_to :sorteo, AzarApp.Sorteos.Sorteo
    belongs_to :usuario, AzarApp.Cuentas.Usuario

    timestamps(type: :utc_datetime)
  end

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:numero, :estado, :sorteo_id, :usuario_id])
    |> validate_required([:numero, :estado, :sorteo_id])
  end
end
