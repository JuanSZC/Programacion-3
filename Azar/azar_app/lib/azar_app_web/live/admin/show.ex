defmodule AzarAppWeb.Admin.SorteoLive.Show do
  use AzarAppWeb, :live_view
  alias AzarApp.Sorteos

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    sorteo = Sorteos.get_sorteo_con_tickets!(id)

    {:ok,
     socket
     |> assign(:sorteo, sorteo)
     |> assign(:selected_ticket, nil)
     |> stream(:tickets, sorteo.tickets)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto space-y-8">
      <%!-- ENCABEZADO --%>
      <.header>
        Sorteo: {@sorteo.titulo}
        <:subtitle>Visualiza y gestiona el estado de los tickets para este sorteo.</:subtitle>
        <:actions>
          <.link navigate={~p"/admin/sorteos"} class="btn btn-ghost rounded-xl gap-2 font-bold text-base-content/70 hover:bg-base-200">
            <.icon name="hero-arrow-left" class="size-5" />
            Volver a la lista
          </.link>
        </:actions>
      </.header>

      <%!-- PANEL DE INFORMACIÓN (Detalles del Ticket) --%>
      <div class="min-h-[200px] transition-all duration-300">
        <%= if @selected_ticket do %>
          <div class="bg-base-100 rounded-3xl p-6 md:p-8 shadow-sm border border-base-200 flex flex-col md:flex-row gap-6 justify-between items-start relative overflow-hidden">
            <div class="absolute -top-10 -right-10 w-48 h-48 bg-primary/5 rounded-full blur-3xl pointer-events-none"></div>

            <div class="flex-1 space-y-6 z-10 w-full">
              <div class="flex items-center gap-4">
                <div class="flex items-center justify-center size-16 rounded-2xl bg-primary/10 text-primary font-black text-2xl shadow-inner">
                  {@selected_ticket.numero}
                </div>
                <div>
                  <h3 class="text-2xl font-bold text-base-content">Detalles del Ticket</h3>
                  <div class="flex items-center gap-2 mt-1">
                    <span class="text-sm font-medium text-base-content/60">Estado:</span>
                    <span class={[
                      "badge font-bold px-3 py-3 gap-1",
                      if(@selected_ticket.estado == "vendido", do: "badge-success text-white border-0", else: "badge-ghost border-0 bg-base-200")
                    ]}>
                      <%= if @selected_ticket.estado == "vendido" do %>
                        <.icon name="hero-check-circle-mini" class="size-4" />
                      <% else %>
                        <.icon name="hero-ticket-mini" class="size-4" />
                      <% end %>
                      <%= String.capitalize(@selected_ticket.estado) %>
                    </span>
                  </div>
                </div>
              </div>

              <%= if @selected_ticket.usuario do %>
                <div class="bg-base-200/50 rounded-2xl p-5 border border-base-200/50 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                  <div class="space-y-1">
                    <p class="text-xs font-bold uppercase tracking-wider text-base-content/50">Propietario del Ticket</p>
                    <p class="font-bold text-lg flex items-center gap-2 text-base-content">
                      <.icon name="hero-user" class="size-5 text-primary" />
                      {@selected_ticket.usuario.nombre}
                    </p>
                    <p class="text-sm font-medium text-base-content/70 flex items-center gap-2">
                      <.icon name="hero-identification" class="size-4 opacity-70" />
                      Cédula/ID: {@selected_ticket.usuario.cedula}
                    </p>
                  </div>

                  <.link
                    navigate={~p"/admin/usuarios/#{@selected_ticket.usuario.id}"}
                    class="btn btn-primary rounded-xl shadow-lg shadow-primary/30 gap-2 w-full sm:w-auto hover:-translate-y-0.5 transition-transform"
                  >
                    <.icon name="hero-user-circle" class="size-5" />
                    Gestionar Usuario
                  </.link>
                </div>
              <% else %>
                <div class="bg-base-200/50 rounded-2xl p-5 border border-base-200/50 flex items-center gap-3 text-base-content/60 font-medium">
                  <.icon name="hero-information-circle" class="size-6" />
                  Este ticket está disponible en el inventario. Aún no tiene dueño.
                </div>
              <% end %>
            </div>

            <button phx-click="close_details" class="btn btn-circle btn-ghost btn-sm absolute top-4 right-4 text-base-content/40 hover:text-base-content z-10 bg-base-200">
              <.icon name="hero-x-mark" class="size-5" />
            </button>
          </div>
        <% else %>
          <div class="h-full bg-base-100/30 border-2 border-dashed border-base-300 rounded-3xl flex flex-col items-center justify-center p-12 text-base-content/40 transition-all hover:bg-base-100 hover:border-primary/30 group cursor-default">
            <.icon name="hero-hand-raised" class="size-10 mb-3 group-hover:-translate-y-1 transition-transform group-hover:text-primary/50" />
            <p class="font-bold text-lg">Ningún ticket seleccionado</p>
            <p class="text-sm font-medium mt-1">Haz clic en cualquier número de la cuadrícula inferior para ver su estado</p>
          </div>
        <% end %>
      </div>

      <%!-- CUADRÍCULA DE TICKETS --%>
      <div class="bg-base-100 p-6 md:p-8 rounded-3xl shadow-sm border border-base-200">
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-8 gap-4">
          <h2 class="text-xl font-bold text-base-content">Inventario de Tickets</h2>
          <div class="flex items-center gap-5 bg-base-200 px-4 py-2.5 rounded-xl text-sm font-bold text-base-content/70">
            <span class="flex items-center gap-2">
              <span class="w-3 h-3 bg-success rounded-full shadow-[0_0_8px_rgba(0,255,0,0.5)]"></span> Vendidos
            </span>
            <span class="flex items-center gap-2">
              <span class="w-3 h-3 bg-base-300 border border-base-content/10 rounded-full"></span> Disponibles
            </span>
          </div>
        </div>

        <div class="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 lg:grid-cols-10 xl:grid-cols-12 gap-3" id="tickets-grid" phx-update="stream">
          <div
            :for={{id, ticket} <- @streams.tickets}
            id={id}
            phx-click="show_ticket"
            phx-value-id={ticket.id}
            class={[
              "relative aspect-square flex items-center justify-center rounded-xl cursor-pointer font-extrabold text-lg transition-all duration-200 hover:-translate-y-1 active:scale-95 border-b-4",
              if(ticket.estado == "vendido",
                do: "bg-success text-success-content border-success-content/20 shadow-md shadow-success/20 hover:brightness-110",
                else: "bg-base-200 text-base-content/70 border-base-300 hover:bg-base-300 hover:text-base-content shadow-sm")
            ]}
          >
            {ticket.numero}
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("show_ticket", %{"id" => ticket_id}, socket) do
    ticket = Enum.find(socket.assigns.sorteo.tickets, fn t -> t.id == String.to_integer(ticket_id) end)
    {:noreply, assign(socket, :selected_ticket, ticket)}
  end

  @impl true
  def handle_event("close_details", _, socket) do
    {:noreply, assign(socket, :selected_ticket, nil)}
  end
end
