defmodule AzarAppWeb.AzarLive do
  use AzarAppWeb, :live_view

  # Esto se ejecuta apenas entras a la web
  def mount(_params, _session, socket) do
    # Guardamos en el "socket" (la memoria de la página) los valores iniciales
    {:ok, assign(socket, nombre: "", contador: 0, formulario_enviado: false)}
  end

  # Cuando el usuario envía el nombre
  def handle_event("guardar_nombre", %{"user_name" => name}, socket) do
    {:noreply, assign(socket, nombre: name, formulario_enviado: true)}
  end

  # Cuando el usuario hace clic en el botón
  def handle_event("sumar_clic", _params, socket) do
    # update toma el valor actual del contador y le suma 1
    {:noreply, update(socket, :contador, &(&1 + 1))}
  end

  def handle_event("apagar_sistema", _params, socket) do
  # Esto le dice a la máquina virtual de Erlang que se apague inmediatamente
  # El código 0 indica una salida normal sin errores
  System.halt(0)

  {:noreply, socket}
end
end
