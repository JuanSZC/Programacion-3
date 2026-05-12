defmodule AzarApp.Sorteos.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tickets" do
    field :numero, :string
    field :estado, :string, default: "disponible"
    belongs_to :sorteo, AzarApp.Sorteos.Sorteo
    belongs_to :usuario, AzarApp.Cuentas.Usuario

    timestamps()
  end

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:numero, :estado, :sorteo_id, :usuario_id])
    |> validate_required([:numero, :estado])
  end
end
