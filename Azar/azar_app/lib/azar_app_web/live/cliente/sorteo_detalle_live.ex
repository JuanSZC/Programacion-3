defmodule AzarAppWeb.Cliente.SorteoDetalleLive do
  use AzarAppWeb, :live_view
  alias AzarApp.Sorteos
  alias AzarApp.Cuentas

  # Importante para la comunicación en tiempo real
  alias Phoenix.PubSub

  def mount(%{"id" => id}, session, socket) do
    usuario_id = session["usuario_id"]

    # Nos suscribimos al tópico de este sorteo específico
    if connected?(socket), do: PubSub.subscribe(AzarApp.PubSub, "sorteo:#{id}")

    if usuario_id do
      sorteo = Sorteos.get_sorteo_con_tickets!(id)
      {:ok,
       socket
       |> assign(sorteo: sorteo)
       |> assign(usuario_id: usuario_id)
       |> assign(selected_ticket: nil)}
    else
      {:ok, push_navigate(socket, to: "/login")}
    end
  end

  # --- EVENTOS ---

  def handle_event("show_ticket", %{"id" => ticket_id}, socket) do
    # Buscamos el ticket por ID dentro de la precarga del sorteo
    ticket = Enum.find(socket.assigns.sorteo.tickets, fn t ->
      t.id == String.to_integer(ticket_id)
    end)

    {:noreply, assign(socket, selected_ticket: ticket)}
  end

  def handle_event("comprar_ticket", %{"num" => num}, socket) do
    usuario = Cuentas.obtener_usuario!(socket.assigns.usuario_id)
    sorteo = socket.assigns.sorteo

    # 1. Validación de seguridad básica de saldo
    if Decimal.lt?(usuario.saldo_virtual || Decimal.new(0), sorteo.precio_ticket) do
      {:noreply, put_flash(socket, :error, "❌ Saldo insuficiente")}
    else
      # 2. Intentar la compra
      case Sorteos.comprar_ticket(usuario, sorteo, num) do
        {:ok, _ticket} ->
          # 3. Notificar a todos los que están viendo este sorteo
          PubSub.broadcast(AzarApp.PubSub, "sorteo:#{sorteo.id}", :ticket_comprado)

          {:noreply, socket |> put_flash(:info, "¡Compra exitosa del ticket ##{num}!")}

        {:error, mensaje} ->
          {:noreply, put_flash(socket, :error, "Error: #{mensaje}")}
      end
    end
  end

  # --- MANEJO DE TIEMPO REAL (PUBSUB) ---

  # Este mensaje llega cuando cualquier usuario compra un ticket en este sorteo
  def handle_info(:ticket_comprado, socket) do
    sorteo_actualizado = Sorteos.get_sorteo_con_tickets!(socket.assigns.sorteo.id)

    # Actualizamos el ticket seleccionado si es que alguien más lo compró mientras lo veíamos
    nuevo_selected = if socket.assigns.selected_ticket do
      Enum.find(sorteo_actualizado.tickets, & &1.id == socket.assigns.selected_ticket.id)
    else
      nil
    end

    {:noreply,
     socket
     |> assign(sorteo: sorteo_actualizado)
     |> assign(selected_ticket: nuevo_selected)}
  end

  # --- RENDER ---
  # El render que tenías es excelente, solo asegúrate de que el loop
  # use el @sorteo.tickets actualizado por PubSub.

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-base-200/30 to-base-100 py-8 px-4 md:py-12 md:px-8 animate-in fade-in duration-700">
      <div class="max-w-7xl mx-auto space-y-8 relative">

        <%!-- FLASH MESSAGES --%>
        <div class="fixed top-6 right-6 z-[100] flex flex-col gap-4 w-72 md:w-96 pointer-events-none">
          <%= if msg = Phoenix.Flash.get(@flash, :error) do %>
            <div class="flex items-start gap-4 bg-error text-error-content p-5 rounded-2xl shadow-2xl animate-in slide-in-from-right-8 pointer-events-auto">
              <.icon name="hero-exclamation-triangle-solid" class="size-6" />
              <p class="font-black text-[11px] uppercase tracking-widest mt-1"><%= msg %></p>
            </div>
          <% end %>
          <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
            <div class="flex items-start gap-4 bg-success text-success-content p-5 rounded-2xl shadow-2xl animate-in slide-in-from-right-8 pointer-events-auto">
              <.icon name="hero-check-circle-solid" class="size-6" />
              <p class="font-black text-[11px] uppercase tracking-widest mt-1"><%= msg %></p>
            </div>
          <% end %>
        </div>

        <%!-- HEADER --%>
        <header class="bg-base-100/80 backdrop-blur-2xl p-6 rounded-[2.5rem] shadow-xl border border-base-200/60 flex flex-col md:flex-row items-center justify-between gap-6">
          <div class="flex items-center gap-5">
            <.link navigate={~p"/cliente/sorteos"} class="p-4 bg-base-200 hover:bg-primary/10 hover:text-primary rounded-2xl transition-all group">
              <.icon name="hero-arrow-left-solid" class="size-6 group-hover:-translate-x-1 transition-transform" />
            </.link>
            <div>
              <h1 class="text-3xl font-black italic uppercase tracking-tighter"><%= @sorteo.titulo %></h1>
              <p class="text-[11px] font-black uppercase tracking-widest opacity-50">Precio Ticket: <span class="text-primary">$<%= @sorteo.precio_ticket %></span></p>
            </div>
          </div>
        </header>

        <%!-- SELECCIÓN --%>
        <div class="relative">
          <%= if @selected_ticket do %>
            <div class="bg-base-100/90 backdrop-blur-3xl p-8 rounded-[3rem] shadow-2xl border border-base-200/60 flex flex-col md:flex-row justify-between items-center gap-8 animate-in zoom-in-95 duration-300">
              <div>
                <p class="text-[10px] font-black uppercase tracking-[0.3em] opacity-40">Número Seleccionado</p>
                <h2 class="text-7xl font-black italic tracking-tighter text-base-content">#<%= @selected_ticket.numero %></h2>
              </div>

              <%= if @selected_ticket.estado == "disponible" do %>
                <button phx-click="comprar_ticket" phx-value-num={@selected_ticket.numero}
                  class="btn btn-success h-16 px-12 rounded-2xl font-black shadow-lg shadow-success/20 hover:-translate-y-1 transition-all uppercase tracking-widest gap-3">
                  <.icon name="hero-shopping-cart-solid" class="size-6" />
                  Comprar Ticket
                </button>
              <% else %>
                <div class="bg-base-200 p-6 rounded-[2rem] border border-base-300 flex items-center gap-4">
                  <%= if @selected_ticket.usuario_id == @usuario_id do %>
                    <span class="text-primary font-black uppercase italic tracking-widest">✨ Ya es tuyo</span>
                  <% else %>
                    <span class="opacity-30 font-black uppercase tracking-widest">🔒 Vendido</span>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% else %>
            <div class="flex flex-col items-center justify-center p-12 bg-base-100/50 rounded-[3rem] border-2 border-dashed border-base-300">
              <.icon name="hero-cursor-arrow-ripple-solid" class="size-10 opacity-20 mb-2" />
              <p class="text-xs font-black uppercase tracking-widest opacity-30">Toca un número para comprar</p>
            </div>
          <% end %>
        </div>

        <%!-- GRID DE TICKETS --%>
        <div class="bg-base-100/70 backdrop-blur-2xl p-8 rounded-[3rem] border border-base-200/50 shadow-inner">
          <div class="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 lg:grid-cols-10 gap-4">
            <%= for ticket <- Enum.sort_by(@sorteo.tickets, &String.to_integer(&1.numero)) do %>
              <div phx-click="show_ticket" phx-value-id={ticket.id}
                class={[
                  "h-16 flex items-center justify-center rounded-2xl cursor-pointer text-xl font-black transition-all duration-300 select-none shadow-sm",
                  ticket.estado == "disponible" && "bg-base-100 border border-base-300 hover:border-success hover:bg-success/10 hover:text-success hover:-translate-y-1",
                  ticket.estado == "vendido" && ticket.usuario_id == @usuario_id && "bg-primary text-primary-content ring-4 ring-primary/30 scale-105",
                  ticket.estado == "vendido" && ticket.usuario_id != @usuario_id && "bg-base-300 opacity-20 cursor-not-allowed"
                ]}>
                <%= ticket.numero %>
              </div>
            <% end %>
          </div>
        </div>

      </div>
    </div>
    """
  end
end
