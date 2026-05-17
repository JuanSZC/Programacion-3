defmodule AzarApp.Notificaciones.Notificacion do
  @moduledoc """
  Módulo AzarApp.Notificaciones.Notificacion: lógica relacionada con notificacion.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "notificaciones" do
    field :ticket_numero, :string
    field :monto_premio, :decimal
    field :tipo_premio, :string
    field :leida, :boolean, default: false

    belongs_to :usuario, AzarApp.Cuentas.Usuario
    belongs_to :sorteo, AzarApp.Sorteos.Sorteo

    timestamps()
  end

  @doc """
  Breve: changeset.
  """
  def changeset(notificacion, attrs) do
    notificacion
    |> cast(attrs, [:usuario_id, :sorteo_id, :ticket_numero, :monto_premio, :tipo_premio, :leida])
    |> validate_required([:usuario_id, :sorteo_id, :ticket_numero, :monto_premio, :tipo_premio])
  end
end
