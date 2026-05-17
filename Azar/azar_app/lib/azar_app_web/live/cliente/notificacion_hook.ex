defmodule AzarAppWeb.Cliente.NotificacionHook do
  @moduledoc false
  import Phoenix.LiveView
  import Phoenix.Component
  alias AzarApp.Notificaciones
  alias Phoenix.PubSub

  @doc """
  Breve: on_mount.
  """
  def on_mount(:default, _params, session, socket) do
    usuario_id = session["usuario_id"]

    if usuario_id && connected?(socket) do
      PubSub.subscribe(AzarApp.PubSub, "usuario:#{usuario_id}")
    end

    pendientes = if usuario_id, do: Notificaciones.pendientes(usuario_id), else: []

    socket =
      socket
      |> assign(:notificaciones_pendientes, pendientes)
      |> assign(:notificacion_activa, List.first(pendientes))
      |> attach_hook(:premio_info, :handle_info, fn
        {:premio_ganado, notificacion}, socket ->
          {:halt,
           socket
           |> assign(:notificaciones_pendientes, [notificacion | socket.assigns.notificaciones_pendientes])
           |> assign(:notificacion_activa, notificacion)}

        _msg, socket ->
          {:cont, socket}
      end)
      |> attach_hook(:premio_event, :handle_event, fn
        "cerrar_notificacion", %{"id" => id_str}, socket ->
          id = String.to_integer(id_str)
          Notificaciones.marcar_como_leida(id)

          pendientes =
            Enum.reject(socket.assigns.notificaciones_pendientes, &(&1.id == id))

          {:halt,
           socket
           |> assign(:notificaciones_pendientes, pendientes)
           |> assign(:notificacion_activa, List.first(pendientes))}

        _event, _params, socket ->
          {:cont, socket}
      end)

    {:cont, socket}
  end
end
