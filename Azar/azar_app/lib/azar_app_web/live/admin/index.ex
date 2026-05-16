defmodule AzarAppWeb.Admin.SorteoLive.Index do
  use AzarAppWeb, :live_view
  alias AzarApp.Sorteos

  # MOUNT
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(AzarApp.PubSub, "sorteos")

    sorteos = Sorteos.list_sorteos()
    socket = assign(socket, :esta_vacio, Enum.empty?(sorteos))
    {:ok, stream(socket, :sorteos, sorteos)}
  end

  # ROUTING & PARAMS
  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Crear Nuevo Sorteo")
    |> assign(:sorteo, %AzarApp.Sorteos.Sorteo{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Panel de Administración")
    |> assign(:sorteo, nil)
  end

  # UI
  @impl true
  def render(assigns) do
    ~H"""
    <AzarAppWeb.AdminSidebar.sidebar current_page="sorteos">
      <div class="w-full animate-in fade-in duration-700 relative z-10">

        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-12">
          <div class="flex flex-col gap-2">
            <div class="inline-flex items-center gap-2 bg-primary/10 px-4 py-2 rounded-full border border-primary/20 w-fit">
                <.icon name="hero-command-line-solid" class="size-4 text-primary" />
                <span class="text-[10px] font-black uppercase tracking-[0.3em] text-primary">Administración</span>
            </div>
            <h1 class="text-4xl md:text-5xl font-black italic uppercase tracking-tighter text-base-content mt-1">
              Panel de <span class="text-primary drop-shadow-md">Sorteos</span>
            </h1>
            <p class="text-xs font-bold opacity-40 uppercase tracking-[0.2em] mt-1">
              Gestiona tus rifas, supervisa tickets y elige ganadores.
            </p>
          </div>

          <.link patch={~p"/admin/sorteos/new"} class="btn btn-primary h-14 px-8 rounded-2xl shadow-xl shadow-primary/30 gap-3 w-full sm:w-auto hover:-translate-y-1 hover:shadow-primary/40 transition-all font-black text-xs uppercase tracking-widest border border-primary/50 group">
            <div class="bg-white/20 p-1.5 rounded-lg group-hover:scale-110 transition-transform">
              <.icon name="hero-plus-solid" class="size-5" />
            </div>
            Nuevo Sorteo
          </.link>
        </div>

        <%= if @esta_vacio do %>
          <div class="h-[50vh] min-h-[400px] bg-base-100/50 backdrop-blur-sm border-2 border-dashed border-base-300/50 rounded-[3rem] flex flex-col items-center justify-center py-16 px-6 text-base-content/40 transition-all hover:bg-base-100/80 hover:border-primary/30 group cursor-default shadow-sm relative overflow-hidden">
            <div class="absolute inset-0 bg-gradient-to-b from-transparent to-base-200/20 pointer-events-none"></div>
            <div class="p-6 bg-base-200/50 rounded-full mb-6 relative group-hover:scale-105 transition-transform duration-500">
              <div class="absolute inset-0 bg-primary/5 rounded-full blur-xl group-hover:bg-primary/10 transition-colors"></div>
              <.icon name="hero-inbox-solid" class="size-16 text-base-content/20 group-hover:text-primary/50 transition-colors relative z-10" />
            </div>
            <h2 class="text-2xl font-black uppercase tracking-tight italic text-base-content/60">No hay sorteos creados</h2>
            <p class="text-[10px] font-bold mt-3 uppercase tracking-widest max-w-sm text-center leading-relaxed text-base-content/40">
              Parece que aún no has registrado ningún sorteo en la plataforma. ¡Haz clic en "Nuevo Sorteo" para comenzar!
            </p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-8" id="sorteos" phx-update="stream">
            <div :for={{id, sorteo} <- @streams.sorteos} id={id} class="bg-base-100/80 backdrop-blur-xl shadow-xl hover:shadow-2xl border border-base-200/60 hover:border-primary/30 transition-all duration-500 rounded-[2.5rem] group relative overflow-hidden flex flex-col">

              <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-primary/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>

              <div class="p-8 flex flex-col h-full">

                <div class="flex justify-between items-start gap-4 mb-4">
                  <h2 class="text-2xl font-black italic uppercase tracking-tight text-base-content leading-tight line-clamp-2 drop-shadow-sm">
                    <%= sorteo.titulo %>
                  </h2>
                  <div class={[
                    "px-3 py-1.5 rounded-xl font-black text-[9px] uppercase tracking-widest whitespace-nowrap border shadow-sm shrink-0",
                    if(sorteo.estado == "activo",
                      do: "bg-success/10 text-success border-success/20",
                      else: "bg-base-200 text-base-content/50 border-base-300")
                  ]}>
                    <%= sorteo.estado %>
                  </div>
                </div>

                <div class="flex flex-wrap gap-3 mt-2">
                  <span class={[
                    "inline-flex items-center gap-2 px-3 py-2 rounded-xl text-[10px] font-black uppercase tracking-wider border border-base-300/30",
                    if(sorteo.tipo_premio == "fijo",
                      do: "bg-warning/10 text-warning border-warning/20",
                      else: "bg-info/10 text-info border-info/20")
                  ]}>
                    <.icon
                      name={if sorteo.tipo_premio == "fijo", do: "hero-lock-closed-solid", else: "hero-arrow-trending-up-solid"}
                      class="size-4"
                    />
                    <%= if sorteo.tipo_premio == "fijo", do: "Premio Fijo", else: "Acumulado" %>
                  </span>
                  <span class="inline-flex items-center gap-2 px-3 py-2 rounded-xl bg-base-200/50 text-[10px] font-black uppercase tracking-wider text-base-content/70 border border-base-300/30">
                    <.icon name="hero-ticket-solid" class="size-4 text-info" />
                    <%= sorteo.total_tickets %> Tickets
                  </span>
                </div>

                <div class="w-full h-px bg-gradient-to-r from-transparent via-base-300/50 to-transparent my-6"></div>

                <div class="flex items-center justify-between mb-4">
                  <div>
                    <p class="text-[9px] uppercase font-black text-base-content/40 tracking-[0.2em] mb-1">Precio Ticket</p>
                    <p class="text-3xl font-black text-primary italic tracking-tighter">
                      $<%= sorteo.precio_ticket %>
                    </p>
                  </div>
                  <div class="text-right">
                    <p class="text-[9px] uppercase font-black text-base-content/40 tracking-[0.2em] mb-1">Ejecución</p>
                    <p class="text-sm font-bold text-base-content/80 uppercase tracking-wider">
                      <%= if sorteo.fecha_ejecucion, do: Calendar.strftime(sorteo.fecha_ejecucion, "%d %b, %Y"), else: "Por definir" %>
                    </p>
                  </div>
                </div>

                <%= if sorteo.estado == "finalizado" and not Enum.empty?(sorteo.numeros_ganadores || []) do %>
                  <div class="flex items-center gap-4 bg-warning/10 border border-warning/20 rounded-2xl px-5 py-4 mb-4">
                    <div class="p-2 bg-warning/20 rounded-xl shrink-0">
                      <.icon name="hero-trophy-solid" class="size-5 text-warning" />
                    </div>
                    <div>
                      <p class="text-[9px] font-black uppercase tracking-widest text-warning/70">Número Ganador</p>
                      <p class="text-2xl font-black italic text-warning leading-none mt-0.5">
                        #<%= Enum.join(sorteo.numeros_ganadores, ", #") %>
                      </p>
                    </div>
                  </div>
                <% end %>

                <div class="flex justify-between items-center mt-auto pt-2">
                  <button
                    phx-click="delete"
                    phx-value-id={sorteo.id}
                    data-confirm="¿Eliminar este sorteo permanentemente?"
                    class="btn btn-circle btn-ghost text-base-content/30 hover:text-error hover:bg-error/10 transition-colors"
                  >
                    <.icon name="hero-trash-solid" class="size-5" />
                  </button>

                  <.link navigate={~p"/admin/sorteos/#{sorteo.id}"} class="btn btn-primary h-12 px-8 rounded-2xl shadow-lg shadow-primary/20 hover:-translate-y-1 transition-transform font-black text-[10px] uppercase tracking-widest gap-2">
                    Gestionar
                    <.icon name="hero-arrow-right-circle-solid" class="size-4" />
                  </.link>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @live_action == :new do %>
        <div class="modal modal-open backdrop-blur-md bg-base-300/40 transition-all duration-500">
          <div class="modal-box relative rounded-[3rem] shadow-2xl p-0 overflow-hidden bg-base-100/95 border border-base-200/60 max-w-2xl animate-in zoom-in-95 duration-300">

            <div class="bg-base-200/50 px-8 py-6 flex justify-between items-center border-b border-base-200/50 backdrop-blur-xl">
              <div class="flex items-center gap-3">
                <div class="p-2 bg-primary/10 rounded-xl">
                  <.icon name="hero-sparkles-solid" class="size-5 text-primary" />
                </div>
                <h3 class="text-xl font-black italic uppercase tracking-tight text-base-content"><%= @page_title %></h3>
              </div>
              <.link patch={~p"/admin/sorteos"} class="btn btn-ghost btn-circle btn-sm hover:bg-error/10 hover:text-error transition-colors">
                <.icon name="hero-x-mark-solid" class="size-5" />
              </.link>
            </div>

            <div class="p-8">
              <.live_component
                module={AzarAppWeb.Admin.SorteoLive.FormComponent}
                id={:new}
                title={@page_title}
                action={@live_action}
                sorteo={@sorteo}
                patch={~p"/admin/sorteos"}
              />
            </div>
          </div>

          <.link patch={~p"/admin/sorteos"} class="modal-backdrop bg-transparent">
            <button>Cerrar</button>
          </.link>
        </div>
      <% end %>
    </AzarAppWeb.AdminSidebar.sidebar>
    """
  end

  # EVENTS
  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    sorteo = Sorteos.get_sorteo!(id)
    {:ok, _} = Sorteos.delete_sorteo(sorteo)

    # El broadcast disparará el handle_info y actualizará la lista,
    # pero actualizamos el estado local por si acaso para reactividad inmediata.
    vacio? = Enum.empty?(Sorteos.list_sorteos())

    {:noreply,
      socket
      |> stream_delete(:sorteos, sorteo)
      |> assign(:esta_vacio, vacio?)}
  end

  # PUBSUB / INFO
  @impl true
  def handle_info({:saved, sorteo}, socket) do
    {:noreply,
      socket
      |> stream_insert(:sorteos, sorteo, at: 0)
      |> assign(:esta_vacio, false)}
  end

  @impl true
  def handle_info({:sorteo_creado, sorteo}, socket) do
    {:noreply,
     socket
     |> stream_insert(:sorteos, sorteo, at: 0)
     |> assign(:esta_vacio, false)}
  end

  @impl true
  def handle_info({:sorteo_eliminado, sorteo}, socket) do
    vacio? = Enum.empty?(Sorteos.list_sorteos())
    {:noreply,
     socket
     |> stream_delete(:sorteos, sorteo)
     |> assign(:esta_vacio, vacio?)}
  end

  @impl true
  def handle_info(:lista_actualizada, socket) do
    sorteos = Sorteos.list_sorteos()
    {:noreply,
     socket
     |> stream(:sorteos, sorteos, reset: true)
     |> assign(:esta_vacio, Enum.empty?(sorteos))}
  end
end
