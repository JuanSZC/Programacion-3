defmodule AzarApp.Notificaciones do
  @moduledoc false
  import Ecto.Query
  alias AzarApp.Repo
  alias AzarApp.Notificaciones.Notificacion
  alias AzarApp.Mailer.NotificacionEmail
  alias AzarApp.Cuentas

  @doc """
  Breve: crear_notificacion_premio.
  """
def crear_notificacion_premio(usuario_id, sorteo, ticket_numero, monto) do
  result =
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

  case result do
   {:ok, notificacion} ->
  Task.start(fn ->
    case Cuentas.obtener_usuario(usuario_id) do
      {:ok, usuario} ->
        NotificacionEmail.premio_ganado(usuario, sorteo, ticket_numero, monto)
      {:error, _} ->
        :ignore
    end
  end)

  {:ok, notificacion}

    error ->
      error
  end
end

  @doc """
  Breve: pendientes.
  """
  def pendientes(usuario_id) do
    Notificacion
    |> where([n], n.usuario_id == ^usuario_id and n.leida == false)
    |> preload(:sorteo)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Breve: marcar_como_leida.
  """
  def marcar_como_leida(notificacion_id) do
    case Repo.get(Notificacion, notificacion_id) do
      nil -> {:error, :not_found}
      n -> n |> Notificacion.changeset(%{leida: true}) |> Repo.update()
    end
  end
end
