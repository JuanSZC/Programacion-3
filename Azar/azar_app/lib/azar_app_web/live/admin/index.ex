defmodule AzarAppWeb.Admin.SorteoLive.Index do
  use AzarAppWeb, :live_view
  alias AzarApp.Sorteos

  @impl true
  def mount(_params, _session, socket) do
    sorteos = Sorteos.list_sorteos()
    # Usamos este booleano para controlar si mostramos el mensaje de vacío
    socket = assign(socket, :esta_vacio, Enum.empty?(sorteos))
    {:ok, stream(socket, :sorteos, sorteos)}
  end

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

  @impl true
  def render(assigns) do
    ~H"""
    <AzarAppWeb.AdminSidebar.sidebar current_page="sorteos">
      <div class="w-full">
        <%!-- CABECERA DEL PANEL --%>
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-10">
          <div>
            <h1 class="text-4xl font-black text-base-content tracking-tight">Panel de Sorteos</h1>
            <p class="text-base-content/60 mt-2 font-medium text-lg">Gestiona tus rifas, supervisa tickets y elige ganadores.</p>
          </div>

          <.link patch={~p"/admin/sorteos/new"} class="btn btn-primary rounded-xl shadow-lg shadow-primary/30 hover:scale-105 transition-transform border-0">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd" />
            </svg>
            Nuevo Sorteo
          </.link>
        </div>

        <%!-- LÓGICA DE ESTADO VACÍO --%>
        <%= if @esta_vacio do %>
          <div class="flex flex-col items-center justify-center py-24 px-6 bg-base-100 rounded-[3rem] border-2 border-dashed border-base-300">
            <div class="relative mb-6">
              <div class="absolute -inset-6 bg-primary/10 rounded-full blur-2xl"></div>
              <div class="relative bg-base-200 p-8 rounded-full">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 text-primary/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 5v2m0 4v2m0 4v2M5 5a2 2 0 00-2 2v3a2 2 0 110 4v3a2 2 0 002 2h14a2 2 0 002-2v-3a2 2 0 110-4V7a2 2 0 00-2-2H5z" />
                </svg>
              </div>
            </div>
            <h2 class="text-2xl font-black text-base-content/80">No hay sorteos creados</h2>
            <p class="text-base-content/50 max-w-xs text-center mt-2 font-medium">
              Parece que aún no has registrado ningún sorteo. ¡Haz clic en "Nuevo Sorteo" para comenzar!
            </p>
          </div>
        <% else %>
          <%!-- GRID DE SORTEOS --%>
          <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6" id="sorteos" phx-update="stream">
            <div :for={{id, sorteo} <- @streams.sorteos} id={id} class="card bg-base-100 shadow-sm hover:shadow-xl border border-base-200 hover:border-primary/40 transition-all duration-300 rounded-2xl group">
              <div class="card-body p-6">
                <div class="flex justify-between items-start gap-4 mb-2">
                  <h2 class="text-xl font-bold text-base-content leading-tight line-clamp-2"><%= sorteo.titulo %></h2>
                  <div class="badge bg-success/10 text-success border-0 font-bold px-3 py-3 uppercase text-[10px] tracking-widest whitespace-nowrap">
                    <%= sorteo.estado %>
                  </div>
                </div>

                <div class="flex flex-wrap gap-2 mt-2">
                   <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-base-200/50 text-xs font-semibold text-base-content/70">
                     🏆 <%= sorteo.cantidad_ganadores %> Ganadores
                   </span>
                   <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-base-200/50 text-xs font-semibold text-base-content/70">
                     🎟️ <%= sorteo.total_tickets %> Tickets
                   </span>
                </div>

                <div class="divider my-2 opacity-30"></div>

                <div class="flex items-center justify-between mb-4">
                  <div>
                    <p class="text-[10px] uppercase font-bold text-base-content/40 tracking-wider mb-1">Precio Ticket</p>
                    <p class="text-2xl font-black text-primary">$<%= sorteo.precio_ticket %></p>
                  </div>
                  <div class="text-right">
                    <p class="text-[10px] uppercase font-bold text-base-content/40 tracking-wider mb-1">Fecha</p>
                    <p class="text-sm font-bold text-base-content/80">
                      <%= if sorteo.fecha_ejecucion, do: Calendar.strftime(sorteo.fecha_ejecucion, "%d %b, %Y"), else: "Por definir" %>
                    </p>
                  </div>
                </div>

                <div class="card-actions justify-between items-center mt-auto pt-4">
                  <button
                    phx-click="delete"
                    phx-value-id={sorteo.id}
                    data-confirm="¿Estás seguro?"
                    class="btn btn-ghost btn-sm text-base-content/40 hover:text-error hover:bg-error/10"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                  </button>

                  <.link navigate={~p"/admin/sorteos/#{sorteo.id}"} class="btn btn-primary btn-sm rounded-lg px-6">
                    Gestionar
                  </.link>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%!-- MODAL DE CREACIÓN --%>
      <%= if @live_action == :new do %>
        <div class="modal modal-open backdrop-blur-sm bg-base-content/20">
          <div class="modal-box relative rounded-3xl shadow-2xl p-0 overflow-hidden bg-base-100 border border-base-200">
            <div class="bg-base-200/50 px-6 py-4 flex justify-between items-center border-b border-base-200">
              <h3 class="text-xl font-bold text-base-content"><%= @page_title %></h3>
              <.link patch={~p"/admin/sorteos"} class="btn btn-ghost btn-sm btn-circle">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>
              </.link>
            </div>
            <div class="p-6">
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
        </div>
      <% end %>
    </AzarAppWeb.AdminSidebar.sidebar>
    """
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    sorteo = Sorteos.get_sorteo!(id)
    {:ok, _} = Sorteos.delete_sorteo(sorteo)

    # Después de borrar, chequeamos si la lista quedó vacía
    vacio? = Enum.empty?(Sorteos.list_sorteos())

    {:noreply,
      socket
      |> stream_delete(:sorteos, sorteo)
      |> assign(:esta_vacio, vacio?)}
  end

  @impl true
  def handle_info({:saved, sorteo}, socket) do
    # Al guardar, ya no está vacío
    {:noreply,
      socket
      |> stream_insert(:sorteos, sorteo)
      |> assign(:esta_vacio, false)}
  end
end
