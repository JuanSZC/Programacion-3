defmodule AzarAppWeb.Cliente.SorteoDetalleLive do
  @moduledoc """
  LiveView encargado de mostrar los detalles de un sorteo específico para el cliente.

  Permite a los usuarios ver el estado de los tickets en tiempo real, alternar
  entre selección individual o múltiple, y realizar la compra interactuando con
  el sistema de saldo y notificando a otros clientes vía PubSub.
  """

  use AzarAppWeb, :live_view
  alias AzarApp.Sorteos
  alias AzarApp.Cuentas
  alias Phoenix.PubSub

  @doc """
  Inicializa el LiveView.

  Obtiene el usuario de la sesión, valida su existencia y lo suscribe a los canales
  de PubSub necesarios para recibir actualizaciones en tiempo real del sorteo y de su cuenta.
  """
  @impl true
  def mount(%{"id" => id}, session, socket) do
    usuario_id = session["usuario_id"]

    if connected?(socket) do
      if usuario_id, do: PubSub.subscribe(AzarApp.PubSub, "usuario:#{usuario_id}")
      PubSub.subscribe(AzarApp.PubSub, "sorteo:#{id}")
    end

    if usuario_id do
      sorteo = Sorteos.get_sorteo_con_tickets!(id)

      {:ok,
       socket
       |> assign(sorteo: sorteo)
       |> assign(usuario_id: usuario_id)
       |> assign(selected_ticket: nil)
       |> assign(modo_multi: false)
       |> assign(tickets_seleccionados: [])}
    else
      {:ok, push_navigate(socket, to: "/login")}
    end
  end

  # ==========================================
  # MANEJO DE EVENTOS (INTERACCIÓN DEL USUARIO)
  # ==========================================

  @doc """
  Alterna el modo de selección de tickets entre individual y múltiple.
  Limpia cualquier selección previa al cambiar de modo.
  """
  @impl true
  def handle_event("toggle_multi", _, socket) do
    {:noreply,
     socket
     |> assign(modo_multi: !socket.assigns.modo_multi)
     |> assign(tickets_seleccionados: [])
     |> assign(selected_ticket: nil)}
  end

  @doc """
  Maneja el clic en un ticket cuando el modo múltiple está DESACTIVADO.
  Selecciona el ticket y hace scroll suave hacia el panel de compra.
  """
  def handle_event("show_ticket", %{"id" => ticket_id}, %{assigns: %{modo_multi: false}} = socket) do
    ticket = Enum.find(socket.assigns.sorteo.tickets, fn t ->
      t.id == String.to_integer(ticket_id)
    end)

    {:noreply,
     socket
     |> assign(selected_ticket: ticket)
     |> push_event("scroll_to_panel", %{})} # Dispara el evento JS para el scroll
  end

  @doc """
  Maneja el clic en un ticket cuando el modo múltiple está ACTIVADO.
  Agrega o elimina el ticket de la lista de selecciones, permitiendo solo tickets disponibles.
  """
  def handle_event("show_ticket", %{"id" => ticket_id, "num" => num}, %{assigns: %{modo_multi: true}} = socket) do
    ticket = Enum.find(socket.assigns.sorteo.tickets, fn t ->
      t.id == String.to_integer(ticket_id)
    end)

    if ticket.estado != "disponible" do
      {:noreply, socket}
    else
      seleccionados = socket.assigns.tickets_seleccionados

      nuevos =
        if num in seleccionados,
          do: List.delete(seleccionados, num),
          else: [num | seleccionados]

      {:noreply, assign(socket, tickets_seleccionados: nuevos)}
    end
  end

  @doc """
  Procesa la compra de un único ticket seleccionado en modo individual.
  Valida el saldo y emite un broadcast a todos los conectados si es exitoso.
  """
  def handle_event("comprar_ticket", %{"num" => num}, socket) do
    usuario = Cuentas.obtener_usuario!(socket.assigns.usuario_id)
    sorteo = socket.assigns.sorteo

    if Decimal.lt?(usuario.saldo_virtual || Decimal.new(0), sorteo.precio_ticket) do
      {:noreply, put_flash(socket, :error, "❌ Saldo insuficiente")}
    else
      case Sorteos.comprar_ticket(usuario, sorteo, num) do
        {:ok, _ticket} ->
          PubSub.broadcast(AzarApp.PubSub, "sorteo:#{sorteo.id}", :ticket_comprado)
          PubSub.broadcast(AzarApp.PubSub, "sorteos", :ticket_comprado)

          {:noreply, put_flash(socket, :info, "¡Compra exitosa del ticket ##{num}!")}

        {:error, mensaje} ->
          {:noreply, put_flash(socket, :error, "Error: #{mensaje}")}
      end
    end
  end

  @doc """
  Procesa la compra en lote de todos los tickets seleccionados en modo múltiple.
  Valida el saldo total necesario y reporta cuántos se compraron con éxito frente a los fallidos.
  """
  def handle_event("comprar_multiples", _, socket) do
    usuario = Cuentas.obtener_usuario!(socket.assigns.usuario_id)
    sorteo = socket.assigns.sorteo
    nums = socket.assigns.tickets_seleccionados
    cantidad = length(nums)
    costo_total = Decimal.mult(sorteo.precio_ticket, Decimal.new(cantidad))

    cond do
      cantidad == 0 ->
        {:noreply, put_flash(socket, :error, "Selecciona al menos un ticket")}

      Decimal.lt?(usuario.saldo_virtual || Decimal.new(0), costo_total) ->
        {:noreply, put_flash(socket, :error, "❌ Saldo insuficiente para #{cantidad} tickets ($#{costo_total})")}

      true ->
        # Intentar comprar todos los tickets seleccionados
        resultados = Enum.map(nums, fn num ->
          Sorteos.comprar_ticket(usuario, sorteo, num)
        end)

        errores = Enum.filter(resultados, &match?({:error, _}, &1))

        # Notificar actualizaciones a la red
        PubSub.broadcast(AzarApp.PubSub, "sorteo:#{sorteo.id}", :ticket_comprado)
        PubSub.broadcast(AzarApp.PubSub, "sorteos", :lista_actualizada)

        if Enum.empty?(errores) do
          {:noreply,
           socket
           |> assign(tickets_seleccionados: [])
           |> assign(modo_multi: false)
           |> put_flash(:info, "¡#{cantidad} tickets comprados exitosamente!")}
        else
          ok = cantidad - length(errores)
          {:noreply,
           socket
           |> assign(tickets_seleccionados: [])
           |> put_flash(:info, "#{ok} comprados, #{length(errores)} no disponibles.")}
        end
    end
  end

  # ==========================================
  # MANEJO DE MENSAJES EN TIEMPO REAL (PUBSUB)
  # ==========================================

  @doc "Fuerza el cierre de sesión del usuario si recibe la señal del sistema."
  @impl true
  def handle_info(:forzar_logout, socket) do
    {:noreply, push_navigate(socket, to: "/forzar_logout")}
  end

  @doc "Actualiza el estado del sorteo y del panel actual cuando cualquier usuario compra un ticket."
  @impl true
  def handle_info(:ticket_comprado, socket) do
    sorteo_actualizado = Sorteos.get_sorteo_con_tickets!(socket.assigns.sorteo.id)

    # Actualizar la referencia del ticket seleccionado (por si alguien más lo compró)
    nuevo_selected = if socket.assigns.selected_ticket do
      Enum.find(sorteo_actualizado.tickets, &(&1.id == socket.assigns.selected_ticket.id))
    else
      nil
    end

    {:noreply,
     socket
     |> assign(sorteo: sorteo_actualizado)
     |> assign(selected_ticket: nuevo_selected)
     |> assign(tickets_seleccionados: [])}
  end

  @doc "Notifica al usuario y actualiza la vista si un administrador ejecuta el sorteo."
  @impl true
  def handle_info(:sorteo_ejecutado, socket) do
    sorteo_actualizado = Sorteos.get_sorteo_con_tickets!(socket.assigns.sorteo.id)

    {:noreply,
     socket
     |> assign(sorteo: sorteo_actualizado)
     |> assign(tickets_seleccionados: [])
     |> assign(modo_multi: false)
     |> put_flash(:info, "🏆 ¡El sorteo ha sido ejecutado!")}
  end

  # ==========================================
  # RENDERIZADO DE LA VISTA
  # ==========================================

  @impl true
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
              <p class="text-[11px] font-black uppercase tracking-widest opacity-50">
                Precio Ticket: <span class="text-primary">$<%= @sorteo.precio_ticket %></span>
              </p>
            </div>
          </div>

          <%!-- TOGGLE MODO MULTI --%>
          <button phx-click="toggle_multi"
            class={[
              "btn h-12 px-6 rounded-2xl font-black text-[10px] uppercase tracking-widest gap-2 transition-all border",
              if(@modo_multi,
                do: "btn-secondary shadow-lg shadow-secondary/20",
                else: "bg-base-200/50 border-base-300/50 text-base-content/60 hover:bg-secondary/10 hover:text-secondary hover:border-secondary/30")
            ]}>
            <.icon name={if @modo_multi, do: "hero-x-mark-solid", else: "hero-squares-plus-solid"} class="size-4" />
            <%= if @modo_multi, do: "Cancelar Selección", else: "Selección Múltiple" %>
          </button>
        </header>

        <%!-- PANEL DE SELECCIÓN --%>
        <div id="panel-seleccion">
          <%= if @modo_multi do %>
            <%!-- MODO: MULTI-SELECT --%>
            <div class="bg-base-100/90 backdrop-blur-3xl p-8 rounded-[3rem] shadow-2xl border border-secondary/20 animate-in zoom-in-95 duration-300">
              <%= if Enum.empty?(@tickets_seleccionados) do %>
                <div class="flex flex-col items-center justify-center py-8 text-base-content/30">
                  <.icon name="hero-squares-plus-solid" class="size-10 mb-2 opacity-20" />
                  <p class="text-xs font-black uppercase tracking-widest">Toca varios números para seleccionarlos</p>
                </div>
              <% else %>
                <div class="flex flex-col md:flex-row items-center justify-between gap-6">
                  <div class="flex flex-col gap-2">
                    <p class="text-[10px] font-black uppercase tracking-[0.3em] opacity-40">Tickets Seleccionados</p>
                    <div class="flex flex-wrap gap-2">
                      <%= for num <- Enum.sort(@tickets_seleccionados) do %>
                        <span class="inline-flex items-center justify-center size-12 rounded-2xl bg-secondary text-secondary-content font-black text-lg shadow-md">
                          <%= num %>
                        </span>
                      <% end %>
                    </div>
                  </div>

                  <div class="flex flex-col items-center md:items-end gap-3">
                    <div class="text-right">
                      <p class="text-[9px] font-black uppercase tracking-widest opacity-40"><%= length(@tickets_seleccionados) %> ticket(s)</p>
                      <p class="text-4xl font-black italic text-secondary leading-none">
                        $<%= Decimal.mult(@sorteo.precio_ticket, Decimal.new(length(@tickets_seleccionados))) %>
                      </p>
                    </div>
                    <button phx-click="comprar_multiples"
                      class="btn btn-secondary h-14 px-10 rounded-2xl font-black shadow-lg shadow-secondary/20 hover:-translate-y-1 transition-all uppercase tracking-widest gap-3">
                      <.icon name="hero-shopping-cart-solid" class="size-5" />
                      Comprar <%= length(@tickets_seleccionados) %> Tickets
                    </button>
                  </div>
                </div>
              <% end %>
            </div>

          <% else %>
            <%!-- MODO: INDIVIDUAL --%>
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
          <% end %>
        </div>

        <%!-- GRID DE TICKETS --%>
        <div class="bg-base-100/70 backdrop-blur-2xl p-8 rounded-[3rem] border border-base-200/50 shadow-inner">
          <div class="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 lg:grid-cols-10 gap-4">
            <%= for ticket <- Enum.sort_by(@sorteo.tickets, &String.to_integer(&1.numero)) do %>
              <div
                phx-click="show_ticket"
                phx-value-id={ticket.id}
                phx-value-num={ticket.numero}
                class={[
                  "h-16 flex items-center justify-center rounded-2xl cursor-pointer text-xl font-black transition-all duration-200 select-none shadow-sm",
                  # Lógica de colores según estado y modo
                  ticket.numero in (@sorteo.numeros_ganadores || []) && "bg-warning text-warning-content border-b-4 border-warning-content/40 shadow-lg scale-110 z-10",
                  @modo_multi && ticket.numero in @tickets_seleccionados && "bg-secondary text-secondary-content ring-4 ring-secondary/30 scale-110 shadow-lg",
                  @modo_multi && ticket.estado == "vendido" && ticket.numero not in (@sorteo.numeros_ganadores || []) && "bg-base-300 opacity-20 cursor-not-allowed",
                  @modo_multi && ticket.estado == "disponible" && ticket.numero not in @tickets_seleccionados && "bg-base-100 border border-base-300 hover:border-secondary hover:bg-secondary/10 hover:text-secondary hover:-translate-y-1",
                  not @modo_multi && ticket.estado == "vendido" && ticket.usuario_id == @usuario_id && "bg-primary text-primary-content ring-4 ring-primary/30 scale-105",
                  not @modo_multi && ticket.estado == "vendido" && ticket.usuario_id != @usuario_id && ticket.numero not in (@sorteo.numeros_ganadores || []) && "bg-base-300 opacity-20 cursor-not-allowed",
                  not @modo_multi && ticket.estado == "disponible" && "bg-base-100 border border-base-300 hover:border-success hover:bg-success/10 hover:text-success hover:-translate-y-1"
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
