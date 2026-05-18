defmodule AzarAppWeb.Admin.SorteoLive.Show do
  @moduledoc """
  Panel de control de alta fidelidad para el detalle, ejecución y monitoreo de un sorteo.
  """

  use AzarAppWeb, :live_view
  alias AzarApp.Sorteos
  alias AzarApp.ErrorHandler

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(AzarApp.PubSub, "sorteo:#{id}")

    case ErrorHandler.safe_get(fn -> Sorteos.get_sorteo_con_tickets!(id) end) do
      {:ok, sorteo} ->
        # Extraemos los tickets para el stream y limpiamos la relación en el struct
        # para evitar clonar miles de registros en la memoria persistente del socket.
        tickets = sorteo.tickets
        sorteo_limpio = %{sorteo | tickets: []}

        {:ok,
         socket
         |> assign(:selected_ticket, nil)
         |> assign_sorteo_data(sorteo_limpio, tickets)
         |> stream(:tickets, tickets)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Sorteo no encontrado")
         |> push_navigate(to: ~p"/admin/sorteos")}
    end
  end

  # Modificado para recibir la lista de tickets por separado sin saturar el estado
  defp assign_sorteo_data(socket, sorteo, tickets) do
    recaudo = Sorteos.recaudo_actual(sorteo)
    premio = Sorteos.premio_actual(sorteo)
    puede_jugar? = Sorteos.puede_jugar_ahora?(sorteo) and sorteo.estado == "activo"
    tickets_vendidos = Enum.count(tickets, &(&1.estado == "vendido"))

    socket
    |> assign(:sorteo, sorteo)
    |> assign(:recaudo_actual, recaudo)
    |> assign(:premio_actual, premio)
    |> assign(:puede_jugar?, puede_jugar?)
    |> assign(:tickets_vendidos, tickets_vendidos)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AzarAppWeb.AdminSidebar.sidebar current_page="sorteos">
      <div class="max-w-7xl mx-auto space-y-8 animate-in fade-in duration-700 relative z-10">

        <%!-- HEADER --%>
        <div class="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-4">
          <div class="flex flex-col gap-2">
            <h1 class="text-4xl md:text-5xl font-black italic uppercase tracking-tighter text-base-content mt-2">
              Sorteo <span class="text-primary drop-shadow-md"><%= @sorteo.titulo %></span>
            </h1>
          </div>
          <.link navigate={~p"/admin/sorteos"} class="btn btn-ghost rounded-[1.5rem] font-black text-xs uppercase tracking-widest text-base-content/60 gap-3 transition-all border border-transparent hover:border-base-300">
            <.icon name="hero-arrow-left-circle-solid" class="size-6" /> Volver
          </.link>
        </div>

        <%!-- METRICAS EN TIEMPO REAL --%>
        <div class="bg-gradient-to-r from-base-200/80 to-base-200/30 p-8 rounded-[3rem] border border-base-300/80 flex flex-col lg:flex-row justify-between items-center gap-6 shadow-sm">
          <div class="flex flex-col gap-3 w-full lg:w-auto">
            <h3 class="text-2xl font-black uppercase tracking-tight italic flex items-center gap-3 text-base-content">
              Modelo: <span class="text-secondary"><%= if @sorteo.tipo_premio == "fijo", do: "Fijo", else: "Acumulado" %></span>
            </h3>
            <div class="flex flex-wrap items-center gap-4 text-xs font-black uppercase tracking-widest text-base-content/60 bg-base-100/50 p-3 rounded-2xl w-fit border border-base-200">
              <span>Recaudo: $<%= @recaudo_actual %></span>
              <span class="opacity-30">|</span>
              <span class="text-success">Premio: $<%= @premio_actual %></span>
              <span class="opacity-30">|</span>
              <span class="text-info">Vendidos: <%= @tickets_vendidos %></span>
            </div>
          </div>

          <%!-- ACCIONES CRÍTICAS --%>
          <div class="flex flex-col items-center lg:items-end gap-2 w-full lg:w-auto">
            <%= cond do %>
              <% @sorteo.estado == "finalizado" -> %>
                <div class="px-8 py-4 bg-success/10 border-2 border-success/30 rounded-[2rem] flex flex-col items-center shadow-lg shadow-success/10 w-full lg:w-auto">
                  <span class="text-[10px] font-black uppercase tracking-[0.3em] text-success/70 mb-1 flex items-center gap-2">
                    <.icon name="hero-star-solid" class="size-4" /> Finalizado con Éxito
                  </span>
                  <span class="text-2xl font-black italic text-success uppercase tracking-tighter">
                    Ganador: <span class="text-3xl"><%= Enum.join(@sorteo.numeros_ganadores || [], ", ") %></span>
                  </span>
                </div>
              <% @sorteo.estado == "activo" -> %>
                <div class="flex flex-col sm:flex-row gap-3 w-full lg:w-auto">
                  <button phx-click="cancelar_sorteo" data-confirm="¿Estás seguro de cancelar este sorteo? Se devolverá el saldo íntegro a todos los usuarios y la acción es irreversible." class="btn bg-error/10 text-error border-error/20 hover:bg-error hover:text-white h-16 px-8 rounded-[2rem] font-black text-sm uppercase tracking-widest transition-all w-full sm:w-auto">
                    Cancelar Sorteo
                  </button>
                  <button phx-click="jugar_ahora" data-confirm="¿Deseas ejecutar la tómbola digital en este momento?" disabled={not @puede_jugar?} class={["btn h-16 px-10 rounded-[2rem] font-black text-sm uppercase tracking-widest shadow-xl transition-all w-full sm:w-auto", if(@puede_jugar?, do: "btn-primary", else: "btn-disabled opacity-40 grayscale")]}>
                     ¡Jugar Ahora!
                  </button>
                </div>
              <% true -> %>
                <div class="px-8 py-4 bg-error/10 border-2 border-error/30 rounded-[2rem] text-error font-black uppercase tracking-tighter text-center w-full lg:w-auto">
                  <%= String.capitalize(@sorteo.estado) %>
                </div>
            <% end %>
          </div>
        </div>

        <%!-- INSPECTOR DE TICKET ON-DEMAND --%>
        <div class="min-h-[140px]">
          <%= if @selected_ticket do %>
            <div class="bg-base-100/90 backdrop-blur-2xl rounded-[3rem] p-8 md:p-10 shadow-2xl border border-base-200/60 flex flex-col lg:flex-row gap-8 justify-between items-start relative animate-in slide-in-from-bottom-4 duration-300">
              <div class="flex-1 space-y-6 z-10 w-full">
                <div class="flex items-center gap-6">
                  <div class="size-20 rounded-[2rem] bg-primary/10 border border-primary/20 text-primary flex items-center justify-center font-black text-4xl shadow-inner italic">
                    <%= @selected_ticket.numero %>
                  </div>
                  <div>
                    <h3 class="text-2xl font-black uppercase tracking-tight italic mb-1">Ticket <%= @selected_ticket.numero %></h3>
                    <span class={["px-4 py-1.5 rounded-xl font-black text-[10px] uppercase border shadow-sm", if(@selected_ticket.estado == "vendido", do: "bg-success/10 text-success border-success/20", else: "bg-base-200 text-base-content/50 border-base-300")]}>
                      <%= @selected_ticket.estado %>
                    </span>
                  </div>
                </div>

                <%= if @selected_ticket.usuario do %>
                  <div class="bg-base-200/40 rounded-[2rem] p-6 border border-base-300/50 flex flex-col sm:flex-row justify-between items-center gap-6">
                    <div>
                      <p class="text-[10px] font-black uppercase tracking-[0.2em] text-base-content/40 mb-1">Propietario Adquirente</p>
                      <p class="font-black text-xl flex items-center gap-3 text-base-content uppercase tracking-tight italic">
                         <%= @selected_ticket.usuario.nombre %>
                      </p>
                      <p class="text-xs font-medium text-base-content/60 mt-0.5"><%= @selected_ticket.usuario.email %></p>
                    </div>
                    <.link navigate={~p"/admin/usuarios/#{@selected_ticket.usuario.id}"} class="btn btn-primary h-12 px-6 rounded-2xl shadow-xl font-black text-xs uppercase tracking-widest">
                       Ver Perfil
                    </.link>
                  </div>
                <% else %>
                  <div class="text-xs font-bold text-base-content/40 uppercase tracking-widest bg-base-200/20 p-4 rounded-xl border border-base-200/50">
                    Este número no posee transacciones comerciales vigentes.
                  </div>
                <% end %>
              </div>
              <button phx-click="close_details" class="btn btn-circle btn-ghost absolute top-6 right-6 hover:bg-base-200">
                <.icon name="hero-x-mark" class="size-6" />
              </button>
            </div>
          <% else %>
            <div class="h-[140px] bg-base-100/50 border-2 border-dashed border-base-300 rounded-[3rem] flex flex-col items-center justify-center p-6 text-base-content/40 transition-colors">
              <.icon name="hero-cursor-arrow-rays-solid" class="size-6 mb-2 opacity-30" />
              <p class="font-black text-sm uppercase tracking-widest italic">Selecciona un cuadrante numérico para inspección</p>
            </div>
          <% end %>
        </div>

        <%!-- GRILLA DINÁMICA DE TICKETS --%>
        <div class="bg-base-100/80 backdrop-blur-xl p-8 md:p-10 rounded-[3rem] shadow-xl border border-base-200/60">
          <div class="grid grid-cols-5 sm:grid-cols-8 md:grid-cols-10 lg:grid-cols-12 xl:grid-cols-16 gap-3" id="tickets-grid" phx-update="stream">
            <div :for={{id, ticket} <- @streams.tickets} id={id} phx-click="show_ticket" phx-value-id={ticket.id}
              class={[
                "relative aspect-square flex items-center justify-center rounded-2xl cursor-pointer font-black text-lg transition-all duration-300 border-b-4",
                cond do
                  ticket.numero in (@sorteo.numeros_ganadores || []) -> "bg-warning text-warning-content border-warning-content/40 shadow-lg scale-110 z-10 animate-bounce"
                  ticket.estado == "vendido" -> "bg-success text-white border-success-content/30 shadow-md hover:scale-105"
                  true -> "bg-base-200/80 text-base-content/50 border-base-300 hover:border-primary/40 hover:bg-base-200"
                end
              ]}>
              <%= ticket.numero %>
            </div>
          </div>
        </div>
      </div>
    </AzarAppWeb.AdminSidebar.sidebar>
    """
  end

  @impl true
  def handle_event("show_ticket", %{"id" => ticket_id}, socket) do
    # OPTIMIZACIÓN: En lugar de buscar en una lista masiva en memoria,
    # cargamos el ticket y su usuario de forma aislada y bajo demanda.
    ticket = Sorteos.get_ticket_con_usuario!(ticket_id)
    {:noreply, assign(socket, :selected_ticket, ticket)}
  end

  @impl true
  def handle_event("close_details", _, socket), do: {:noreply, assign(socket, :selected_ticket, nil)}

  @impl true
  def handle_event("jugar_ahora", _, socket) do
    case Sorteos.realizar_sorteo!(socket.assigns.sorteo) do
      {:ok, _sorteo_actualizado} ->
        {:noreply, put_flash(socket, :info, "Sorteo realizado con éxito.")}
      {:error, razon} ->
        {:noreply, put_flash(socket, :error, "❌ Error: #{razon}")}
    end
  end

  @impl true
  def handle_event("cancelar_sorteo", _, socket) do
    case Sorteos.cancelar_sorteo(socket.assigns.sorteo) do
      {:ok, _sorteo_cancelado} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sorteo cancelado exitonamente. Se ha reembolsado a los participantes.")
         |> push_navigate(to: ~p"/admin/sorteos")}

      {:error, razon} ->
        {:noreply, put_flash(socket, :error, "❌ No se pudo cancelar el sorteo: #{razon}")}
    end
  end

  # =========================================================================
  # RECEPCIÓN DE EVENTOS PUB_SUB (TIEMPO REAL ULTRA EFICIENTE)
  # =========================================================================

  @impl true
  def handle_info(:ticket_comprado, socket) do
    # Evitamos "reset: true". Recargamos la metadata y refrescamos únicamente los elementos.
    sorteo_actualizado = Sorteos.get_sorteo_con_tickets!(socket.assigns.sorteo.id)
    tickets = sorteo_actualizado.tickets
    sorteo_limpio = %{sorteo_actualizado | tickets: []}

    {:noreply,
     socket
     |> assign_sorteo_data(sorteo_limpio, tickets)
     |> update_selected_ticket(tickets)
     |> stream(:tickets, tickets, reset: true)} # Solo usar reset si es estrictamente obligatorio por cambios masivos concurrentes.
  end

  @impl true
  def handle_info(:sorteo_ejecutado, socket) do
    sorteo_actualizado = Sorteos.get_sorteo_con_tickets!(socket.assigns.sorteo.id)
    tickets = sorteo_actualizado.tickets
    sorteo_limpio = %{sorteo_actualizado | tickets: []}

    {:noreply,
     socket
     |> assign_sorteo_data(sorteo_limpio, tickets)
     |> stream(:tickets, tickets, reset: true)}
  end

  @impl true
  def handle_info(:sorteo_cancelado, socket) do
    {:noreply,
     socket
     |> put_flash(:warning, "Este sorteo ha sido cancelado por otro administrador.")
     |> push_navigate(to: ~p"/admin/sorteos")}
  end

  defp update_selected_ticket(socket, tickets) do
    if socket.assigns.selected_ticket do
      ticket_actualizado = Enum.find(tickets, &(&1.id == socket.assigns.selected_ticket.id))
      # Si el ticket inspeccionado cambió de estado, volvemos a traer sus datos actualizados
      if ticket_actualizado && ticket_actualizado.estado != socket.assigns.selected_ticket.estado do
        assign(socket, :selected_ticket, Sorteos.get_ticket_con_usuario!(ticket_actualizado.id))
      else
        socket
      end
    else
      socket
    end
  end
end
