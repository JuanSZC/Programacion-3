defmodule AzarAppWeb.Cliente.NotificacionHook do
  @moduledoc """
  Hook on_mount que se aplica a todas las rutas /cliente.

  Hace tres cosas sin tocar cada LiveView individualmente:
  1. Carga notificaciones de premio pendientes al montar.
  2. Se suscribe al tópico PubSub del usuario para recibir premios en tiempo real.
  3. Intercepta con attach_hook los mensajes PubSub y los eventos del modal.
  """
  import Phoenix.LiveView
  import Phoenix.Component
  alias AzarApp.Notificaciones
  alias Phoenix.PubSub

  def on_mount(:default, _params, session, socket) do
    usuario_id = session["usuario_id"]

    # Suscripción en tiempo real solo si el socket ya está conectado
    if usuario_id && connected?(socket) do
      PubSub.subscribe(AzarApp.PubSub, "usuario:#{usuario_id}")
    end

    # Cargamos premios no leídos al entrar (para el caso offline)
    pendientes = if usuario_id, do: Notificaciones.pendientes(usuario_id), else: []

    socket =
      socket
      |> assign(:notificaciones_pendientes, pendientes)
      |> assign(:notificacion_activa, List.first(pendientes))
      # Intercepta mensajes PubSub — cuando llega un premio en vivo
      |> attach_hook(:premio_info, :handle_info, fn
        {:premio_ganado, notificacion}, socket ->
          {:halt,
           socket
           |> assign(:notificaciones_pendientes, [notificacion | socket.assigns.notificaciones_pendientes])
           |> assign(:notificacion_activa, notificacion)}

        # Cualquier otro mensaje lo deja pasar al LiveView correspondiente
        _msg, socket ->
          {:cont, socket}
      end)
      # Intercepta el evento de cerrar el modal desde el layout
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

        # Cualquier otro evento lo deja pasar al LiveView correspondiente
        _event, _params, socket ->
          {:cont, socket}
      end)

    {:cont, socket}
  end
end
