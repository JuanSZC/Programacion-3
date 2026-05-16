defmodule AzarAppWeb.Admin.SorteoLive.Show do
  use AzarAppWeb, :live_view
  alias AzarApp.Sorteos

  # MOUNT
  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(AzarApp.PubSub, "sorteo:#{id}")

    sorteo = Sorteos.get_sorteo_con_tickets!(id)
    {:ok,
     socket
     |> assign(:selected_ticket, nil)
     |> assign_sorteo_data(sorteo)
     |> stream(:tickets, sorteo.tickets)}
  end

  defp assign_sorteo_data(socket, sorteo) do
    recaudo = Sorteos.recaudo_actual(sorteo)
    premio = Sorteos.premio_actual(sorteo)
    puede_jugar? = Sorteos.puede_jugar_ahora?(sorteo) and sorteo.estado == "activo"
    tickets_vendidos = Enum.count(sorteo.tickets, &(&1.estado == "vendido"))

    socket
    |> assign(:sorteo, sorteo)
    |> assign(:recaudo_actual, recaudo)
    |> assign(:premio_actual, premio)
    |> assign(:puede_jugar?, puede_jugar?)
    |> assign(:tickets_vendidos, tickets_vendidos)
  end

  # UI
  @impl true
  def render(assigns) do
    ~H"""
    <AzarAppWeb.AdminSidebar.sidebar current_page="sorteos">
      <div class="max-w-7xl mx-auto space-y-8 animate-in fade-in duration-700 relative z-10">

        <div class="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-4">
          <div class="flex flex-col gap-2">
            <h1 class="text-4xl md:text-5xl font-black italic uppercase tracking-tighter text-base-content mt-2">
              Sorteo <span class="text-primary drop-shadow-md">{@sorteo.titulo}</span>
            </h1>
          </div>
          <.link navigate={~p"/admin/sorteos"} class="btn btn-ghost rounded-[1.5rem] font-black text-xs uppercase tracking-widest text-base-content/60 gap-3 transition-all border border-transparent hover:border-base-300">
            <.icon name="hero-arrow-left-circle-solid" class="size-6" /> Volver
          </.link>
        </div>

        <div class="bg-gradient-to-r from-base-200/80 to-base-200/30 p-8 rounded-[3rem] border border-base-300/80 flex flex-col lg:flex-row justify-between items-center gap-6 shadow-sm">
          <div class="flex flex-col gap-3 w-full lg:w-auto">
            <h3 class="text-2xl font-black uppercase tracking-tight italic flex items-center gap-3 text-base-content">
              Modelo: <span class="text-secondary"><%= if @sorteo.tipo_premio == "fijo", do: "Fijo", else: "Acumulado" %></span>
            </h3>
            <div class="flex flex-wrap items-center gap-4 text-xs font-black uppercase tracking-widest text-base-content/60 bg-base-100/50 p-3 rounded-2xl w-fit border border-base-200">
              <span>Recaudo: ${@recaudo_actual}</span>
              <span class="opacity-30">|</span>
              <span class="text-success">Premio: ${@premio_actual}</span>
            </div>
          </div>

          <div class="flex flex-col items-center lg:items-end gap-2">
            <%= cond do %>
              <% @sorteo.estado == "finalizado" and @tickets_vendidos > 0 -> %>
                <div class="px-8 py-4 bg-success/10 border-2 border-success/30 rounded-[2rem] flex flex-col items-center shadow-lg shadow-success/10">
                  <span class="text-[10px] font-black uppercase tracking-[0.3em] text-success/70 mb-1 flex items-center gap-2">
                    <.icon name="hero-star-solid" class="size-4" /> Finalizado
                  </span>
                  <span class="text-2xl font-black italic text-success uppercase tracking-tighter">
                    Ganador: <span class="text-3xl"><%= Enum.join(@sorteo.numeros_ganadores || [], ", ") %></span>
                  </span>
                </div>
              <% @sorteo.estado == "activo" -> %>
                <button phx-click="jugar_ahora" data-confirm="¿Ejecutar sorteo?" disabled={not @puede_jugar?} class={["btn h-16 px-10 rounded-[2rem] font-black text-sm uppercase tracking-widest shadow-xl transition-all w-full lg:w-auto", if(@puede_jugar?, do: "btn-primary", else: "btn-disabled opacity-40 grayscale")]}>
                   ¡Jugar Ahora!
                </button>
              <% true -> %>
                <div class="px-8 py-4 bg-error/10 border-2 border-error/30 rounded-[2rem] text-error font-black uppercase tracking-tighter text-center">Cerrado / Sin Tickets</div>
            <% end %>
          </div>
        </div>

        <div class="min-h-[220px]">
          <%= if @selected_ticket do %>
            <div class="bg-base-100/90 backdrop-blur-2xl rounded-[3rem] p-8 md:p-10 shadow-2xl border border-base-200/60 flex flex-col lg:flex-row gap-8 justify-between items-start relative animate-in slide-in-from-bottom-4">
              <div class="flex-1 space-y-8 z-10 w-full">
                <div class="flex items-center gap-6">
                  <div class="size-20 rounded-[2rem] bg-primary/10 border border-primary/20 text-primary flex items-center justify-center font-black text-4xl shadow-inner">
                    {@selected_ticket.numero}
                  </div>
                  <div>
                    <h3 class="text-2xl font-black uppercase tracking-tight italic mb-2">Ticket {@selected_ticket.numero}</h3>
                    <span class={["px-4 py-1.5 rounded-full font-black text-[10px] uppercase", if(@selected_ticket.estado == "vendido", do: "bg-success text-white", else: "bg-base-200 text-base-content/60")]}>
                      {@selected_ticket.estado}
                    </span>
                  </div>
                </div>

                <%= if @selected_ticket.usuario do %>
                  <div class="bg-base-200/40 rounded-[2rem] p-6 border border-base-300/50 flex flex-col sm:flex-row justify-between items-center gap-6">
                    <div>
                      <p class="text-[10px] font-black uppercase tracking-[0.2em] text-base-content/40">Propietario</p>
                      <p class="font-black text-xl flex items-center gap-3 text-base-content uppercase tracking-tight italic">
                         {@selected_ticket.usuario.nombre}
                      </p>
                    </div>
                    <.link navigate={~p"/admin/usuarios/#{@selected_ticket.usuario.id}"} class="btn btn-primary h-12 px-6 rounded-2xl shadow-xl font-black text-xs uppercase tracking-widest">
                       Ver Perfil
                    </.link>
                  </div>
                <% end %>
              </div>
              <button phx-click="close_details" class="btn btn-circle btn-ghost absolute top-6 right-6">
                <.icon name="hero-x-mark" class="size-6" />
              </button>
            </div>
          <% else %>
            <div class="h-full bg-base-100/50 border-2 border-dashed border-base-300 rounded-[3rem] flex flex-col items-center justify-center py-16 px-6 text-base-content/40">
              <p class="font-black text-xl uppercase tracking-tighter italic">Selecciona un número</p>
            </div>
          <% end %>
        </div>

        <div class="bg-base-100/80 backdrop-blur-xl p-8 md:p-10 rounded-[3rem] shadow-xl border border-base-200/60">
          <div class="grid grid-cols-5 sm:grid-cols-8 md:grid-cols-10 lg:grid-cols-12 xl:grid-cols-16 gap-3" id="tickets-grid" phx-update="stream">
            <div :for={{id, ticket} <- @streams.tickets} id={id} phx-click="show_ticket" phx-value-id={ticket.id}
              class={[
                "relative aspect-square flex items-center justify-center rounded-2xl cursor-pointer font-black text-lg transition-all duration-300 border-b-4",
                cond do
                  ticket.numero in (@sorteo.numeros_ganadores || []) -> "bg-warning text-warning-content border-warning-content/40 shadow-lg scale-110 z-10 animate-bounce"
                  ticket.estado == "vendido" -> "bg-success text-white border-success-content/30 shadow-md"
                  true -> "bg-base-200/80 text-base-content/50 border-base-300"
                end
              ]}>
              {ticket.numero}
            </div>
          </div>
        </div>
      </div>
    </AzarAppWeb.AdminSidebar.sidebar>
    """
  end

  # EVENTS
  @impl true
  def handle_event("show_ticket", %{"id" => ticket_id}, socket) do
    ticket = Enum.find(socket.assigns.sorteo.tickets, fn t -> t.id == String.to_integer(ticket_id) end)
    {:noreply, assign(socket, :selected_ticket, ticket)}
  end

  @impl true
  def handle_event("close_details", _, socket), do: {:noreply, assign(socket, :selected_ticket, nil)}

  @impl true
  def handle_event("jugar_ahora", _, socket) do
    case Sorteos.realizar_sorteo!(socket.assigns.sorteo) do
      {:ok, _sorteo_actualizado} ->
        # El broadcast se encargará de actualizar la vista mediante handle_info
        {:noreply, put_flash(socket, :info, "Sorteo realizado con éxito")}
      {:error, razon} ->
        {:noreply, put_flash(socket, :error, "Error: #{razon}")}
    end
  end

  # PUBSUB / INFO
  @impl true
  def handle_info(:ticket_comprado, socket) do
    sorteo_actualizado = Sorteos.get_sorteo_con_tickets!(socket.assigns.sorteo.id)

    {:noreply,
     socket
     |> assign_sorteo_data(sorteo_actualizado)
     |> update_selected_ticket(sorteo_actualizado)
     |> stream(:tickets, sorteo_actualizado.tickets, reset: true)}
  end

  @impl true
  def handle_info(:sorteo_ejecutado, socket) do
    sorteo_actualizado = Sorteos.get_sorteo_con_tickets!(socket.assigns.sorteo.id)

    {:noreply,
     socket
     |> assign_sorteo_data(sorteo_actualizado)
     |> stream(:tickets, sorteo_actualizado.tickets, reset: true)}
  end

  # HELPERS
  defp update_selected_ticket(socket, sorteo) do
    if socket.assigns.selected_ticket do
      ticket_actualizado = Enum.find(sorteo.tickets, &(&1.id == socket.assigns.selected_ticket.id))
      assign(socket, :selected_ticket, ticket_actualizado)
    else
      socket
    end
  end
end
