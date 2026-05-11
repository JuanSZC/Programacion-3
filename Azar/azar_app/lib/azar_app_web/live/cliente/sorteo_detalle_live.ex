defmodule AzarAppWeb.Cliente.SorteoDetalleLive do
  use AzarAppWeb, :live_view
  alias AzarApp.Sorteos
  alias AzarApp.Cuentas

  def mount(%{"id" => id}, session, socket) do
    usuario_id = session["usuario_id"]
    sorteo = Sorteos.get_sorteo_con_tickets!(id)

    {:ok,
     socket
     |> assign(sorteo: sorteo)
     |> assign(usuario_id: usuario_id)
     |> assign(selected_ticket: nil)}
  end

  def handle_event("show_ticket", %{"id" => ticket_id}, socket) do
    ticket = Enum.find(socket.assigns.sorteo.tickets, fn t -> t.id == String.to_integer(ticket_id) end)

    {:noreply,
     socket
     |> assign(selected_ticket: ticket)
     |> clear_flash()} # Limpia mensajes anteriores al cambiar de ticket
  end

  def handle_event("comprar_ticket", %{"num" => num}, socket) do
    usuario = Cuentas.obtener_usuario!(socket.assigns.usuario_id)
    sorteo = socket.assigns.sorteo

    if Decimal.lt?(usuario.saldo_virtual, sorteo.precio_ticket) do
      {:noreply,
       socket
       |> put_flash(:error, "❌ Saldo insuficiente (Saldo: $#{usuario.saldo_virtual})")}
    else
      case Sorteos.comprar_ticket(usuario, sorteo, num) do
        {:ok, ticket_comprado} ->
          sorteo_actualizado = Sorteos.get_sorteo_con_tickets!(sorteo.id)

          {:noreply,
           socket
           |> assign(sorteo: sorteo_actualizado)
           |> assign(selected_ticket: ticket_comprado)
           |> put_flash(:info, "¡Compra exitosa del ticket ##{num}!")}

        {:error, _mensaje} ->
          {:noreply, socket |> put_flash(:error, "No se pudo procesar la compra")}
      end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto p-4 md:p-6 space-y-6 relative">

      <%!-- ALERTAS FLOTANTES (Para asegurar que el mensaje se vea) --%>
      <div class="fixed top-5 right-5 z-[100] flex flex-col gap-3 w-72 md:w-80">
        <%= if msg = Phoenix.Flash.get(@flash, :error) do %>
          <div class="alert alert-error shadow-2xl border-2 border-white/10 animate-in fade-in slide-in-from-right-5 duration-300">
            <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
            <span class="text-sm font-bold"><%= msg %></span>
          </div>
        <% end %>

        <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
          <div class="alert alert-info shadow-2xl border-2 border-white/10 animate-in fade-in slide-in-from-right-5 duration-300">
            <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2l4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
            <span class="text-sm font-bold"><%= msg %></span>
          </div>
        <% end %>
      </div>

      <%!-- BOTÓN VOLVER Y TÍTULO --%>
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div class="flex items-center gap-4">
          <.link
            navigate={~p"/cliente/sorteos"}
            class="btn btn-circle btn-outline btn-secondary hover:scale-110 transition-transform"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
          </.link>
          <div>
            <h1 class="text-2xl md:text-3xl font-black italic text-white uppercase tracking-tighter"><%= @sorteo.titulo %></h1>
            <p class="text-primary font-bold">Precio por ticket: $<%= @sorteo.precio_ticket %></p>
          </div>
        </div>
      </div>

      <%!-- PANEL DE COMPRA --%>
      <div class="min-h-[140px]">
        <%= if @selected_ticket do %>
          <div class="bg-neutral text-neutral-content rounded-3xl p-6 md:p-8 flex flex-col md:flex-row justify-between items-center shadow-2xl border border-white/5 animate-in fade-in zoom-in duration-300">
            <div class="text-center md:text-left mb-4 md:mb-0">
              <p class="text-[10px] font-black uppercase tracking-widest opacity-50">Seleccionado</p>
              <h2 class="text-4xl md:text-6xl font-black italic">#<%= @selected_ticket.numero %></h2>
            </div>

            <%= if @selected_ticket.estado == "disponible" do %>
              <button
                phx-click="comprar_ticket"
                phx-value-num={@selected_ticket.numero}
                class="btn btn-primary btn-lg rounded-2xl font-black px-10 shadow-lg shadow-primary/20 hover:scale-105 active:scale-95 transition-all w-full md:w-auto"
              >
                COMPRAR POR $<%= @sorteo.precio_ticket %>
              </button>
            <% else %>
              <div class="flex flex-col items-center md:items-end">
                <span class="badge badge-lg badge-error font-black py-4 px-6 rounded-xl">VENDIDO</span>
                <p class="font-bold mt-2 text-sm text-primary">
                  <%= if @selected_ticket.usuario_id == @usuario_id, do: "✨ ¡Es tuyo!", else: "💔 Ya tiene dueño" %>
                </p>
              </div>
            <% end %>
          </div>
        <% else %>
          <div class="border-2 border-dashed border-base-300 rounded-3xl p-8 text-center opacity-40">
              <p class="text-lg font-bold uppercase tracking-tight">Toca un número para comprar</p>
          </div>
        <% end %>
      </div>

      <%!-- CUADRÍCULA --%>
      <div class="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 lg:grid-cols-10 xl:grid-cols-12 gap-3">
        <%= for ticket <- Enum.sort_by(@sorteo.tickets, &String.to_integer(&1.numero)) do %>
          <div
            phx-click="show_ticket"
            phx-value-id={ticket.id}
            class={[
              "h-16 w-full flex items-center justify-center rounded-xl cursor-pointer text-xl font-black transition-all border-b-4 active:scale-90 select-none",
              ticket.estado == "disponible" && "bg-success text-success-content border-green-800 hover:brightness-110",
              ticket.estado == "vendido" && "bg-blue-600 text-white border-blue-900",
              ticket.estado == "vendido" && ticket.usuario_id == @usuario_id && "ring-4 ring-primary ring-offset-2 ring-offset-base-100",
              ticket.estado == "vendido" && ticket.usuario_id != @usuario_id && "brightness-50 opacity-60"
            ]}
          >
            <%= ticket.numero %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
