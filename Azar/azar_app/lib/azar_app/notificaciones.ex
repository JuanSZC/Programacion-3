defmodule AzarApp.Notificaciones do
  @moduledoc """
  Gestiona las notificaciones de premio para los ganadores de sorteos.
  """
  import Ecto.Query
  alias AzarApp.Repo
  alias AzarApp.Notificaciones.Notificacion

  @doc "Crea una notificación de premio para un ganador."
  def crear_notificacion_premio(usuario_id, sorteo, ticket_numero, monto) do
    %Notificacion{}
    |> Notificacion.changeset(%{
      usuario_id: usuario_id,
      sorteo_id: sorteo.id,
      ticket_numero: ticket_numero,
      monto_premio: monto,
      tipo_premio: sorteo.tipo_premio,
      leida: false
    })
    |> Repo.insert()
  end

  @doc "Devuelve todas las notificaciones no leídas de un usuario, con el sorteo precargado."
  def pendientes(usuario_id) do
    Notificacion
    |> where([n], n.usuario_id == ^usuario_id and n.leida == false)
    |> preload(:sorteo)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc "Marca una notificación específica como leída."
  def marcar_como_leida(notificacion_id) do
    case Repo.get(Notificacion, notificacion_id) do
      nil -> {:error, :not_found}
      n -> n |> Notificacion.changeset(%{leida: true}) |> Repo.update()
    end
  end
end
