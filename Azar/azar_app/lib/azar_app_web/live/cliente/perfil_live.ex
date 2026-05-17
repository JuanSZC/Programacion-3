defmodule AzarAppWeb.Cliente.PerfilLive do
  @moduledoc false

  use AzarAppWeb, :live_view
  alias AzarApp.Cuentas

 @impl true
def mount(_params, session, socket) do
  usuario_id = session["usuario_id"]

  if usuario_id do
    usuario = Cuentas.obtener_usuario!(usuario_id)
    transacciones = Cuentas.listar_transacciones(usuario_id)
    tickets_usuario = AzarApp.Sorteos.list_tickets_por_usuario(usuario_id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(AzarApp.PubSub, "usuario:#{usuario_id}")
    end

    balance_info = Cuentas.obtener_balance_personal(usuario)

    {:ok,
     socket
     |> assign(usuario: usuario)
     |> assign(balance: balance_info)
     |> assign(transacciones: transacciones)
     |> assign(tickets_usuario: tickets_usuario)
     |> assign(show_modal: false)
     |> assign(show_historial_modal: false)
     |> assign(seccion_activa: "info")
     |> assign(editando_campo: nil)
     |> assign(modo_monto: "rapido")
     |> assign(monto_seleccionado: 20000)
     |> assign(metodo_pago: "pse")}
  else
    {:ok, push_navigate(socket, to: "/login")}
  end
end


  @impl true
  def handle_info(:forzar_logout, socket) do
    {:noreply, push_navigate(socket, to: "/forzar_logout")}
  end


  @impl true
  def handle_event("set_seccion", %{"sec" => sec}, socket) do
    {:noreply, assign(socket, seccion_activa: sec, editando_campo: nil)}
  end

  @doc """
  Breve: handle_event.
  """
  def handle_event("editar", %{"campo" => campo}, socket) do
    {:noreply, assign(socket, editando_campo: campo)}
  end

  @doc """
  Breve: handle_event.
  """
  def handle_event("cancelar_edicion", _, socket) do
    {:noreply, assign(socket, editando_campo: nil)}
  end


  @doc """
  Breve: handle_event.
  """
  def handle_event("abrir_historial", _, socket) do
    {:noreply, assign(socket, show_historial_modal: true)}
  end

  @doc """
  Breve: handle_event.
  """
  def handle_event("cerrar_historial", _, socket) do
    {:noreply, assign(socket, show_historial_modal: false)}
  end


  @doc """
  Breve: handle_event.
  """
  def handle_event("guardar_cambios", %{"campo" => campo, "valor" => valor}, socket) do
    case Cuentas.actualizar_campo_usuario(socket.assigns.usuario, campo, valor) do
      {:ok, usuario_actualizado} ->
        {:noreply,
         socket
         |> assign(usuario: usuario_actualizado, editando_campo: nil)
         |> put_flash(:info, "¡#{String.capitalize(campo)} actualizado!")}

      {:error, _mensaje} ->
        {:noreply, put_flash(socket, :error, "Error al actualizar")}
    end
  end


  @doc """
  Breve: handle_event.
  """
  def handle_event("abrir_modal", _, socket) do
    {:noreply,
     assign(socket,
       show_modal: true,
       modo_monto: "rapido",
       monto_seleccionado: 20000,
       metodo_pago: "pse"
     )}
  end

  @doc """
  Breve: handle_event.
  """
  def handle_event("cerrar_modal", _, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end

  @doc """
  Breve: handle_event.
  """
  def handle_event("seleccionar_monto", %{"monto" => monto}, socket) do
    {:noreply, assign(socket, modo_monto: "rapido", monto_seleccionado: String.to_integer(monto))}
  end

  @doc """
  Breve: handle_event.
  """
  def handle_event("activar_manual", _, socket) do
    {:noreply, assign(socket, modo_monto: "manual", monto_seleccionado: 0)}
  end

  @doc """
  Breve: handle_event.
  """
  def handle_event("seleccionar_metodo", %{"metodo" => metodo}, socket) do
    {:noreply, assign(socket, metodo_pago: metodo)}
  end

  @doc """
  Breve: handle_event.
  """
  def handle_event("devolver_ticket", %{"ticket_id" => ticket_id}, socket) do
    usuario = socket.assigns.usuario

    case AzarApp.Sorteos.devolver_ticket(usuario, String.to_integer(ticket_id)) do
      {:ok, _ticket} ->
        usuario_actualizado = AzarApp.Cuentas.obtener_usuario!(usuario.id)
        transacciones = AzarApp.Cuentas.listar_transacciones(usuario.id)
        tickets_usuario = AzarApp.Sorteos.list_tickets_por_usuario(usuario.id)
        nuevo_balance = AzarApp.Cuentas.obtener_balance_personal(usuario_actualizado)

        {:noreply,
         socket
         |> assign(usuario: usuario_actualizado)
         |> assign(balance: nuevo_balance)
         |> assign(transacciones: transacciones)
         |> assign(tickets_usuario: tickets_usuario)
         |> put_flash(:info, "✅ Ticket devuelto y saldo reembolsado")}

      {:error, mensaje} ->
        {:noreply, put_flash(socket, :error, "❌ #{mensaje}")}
    end
  end

  @doc """
  Breve: handle_event.
  """
  def handle_event("confirmar_recarga", params, socket) do
    monto =
      if socket.assigns.modo_monto == "manual" do
        case Integer.parse(Map.get(params, "monto_manual", "0")) do
          {val, _} -> val
          :error -> 0
        end
      else
        socket.assigns.monto_seleccionado
      end

    metodo = socket.assigns.metodo_pago

    if monto < 1000 do
      {:noreply, put_flash(socket, :error, "❌ El monto mínimo de recarga es $1.000")}
    else
      case Cuentas.recargar_saldo(socket.assigns.usuario, monto) do
        {:ok, usuario_actualizado} ->
          metodo_bonito = String.upcase(metodo)

          nuevo_balance = Cuentas.obtener_balance_personal(usuario_actualizado)

          {:noreply,
           socket
           |> assign(usuario: usuario_actualizado)
           |> assign(balance: nuevo_balance)
           |> assign(show_modal: false)
           |> put_flash(:info, "¡Recarga de $#{monto} exitosa vía #{metodo_bonito}!")}

        _ ->
          {:noreply, put_flash(socket, :error, "Error al procesar la recarga")}
      end
    end
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-b from-base-200/30 to-base-100 pb-20 animate-in fade-in zoom-in-95 duration-700">

      <%!-- ALERTAS FLOTANTES PREMIUM --%>
      <div class="fixed top-6 right-6 z-[100] flex flex-col gap-4 w-72 md:w-96 pointer-events-none">
        <%= if msg = Phoenix.Flash.get(@flash, :error) do %>
          <div class="flex items-start gap-4 bg-error/90 backdrop-blur-md text-error-content p-5 rounded-2xl shadow-2xl shadow-error/30 animate-in slide-in-from-right-8 duration-500 pointer-events-auto">
            <div class="p-1.5 bg-error-content/20 rounded-xl shrink-0">
              <.icon name="hero-exclamation-triangle-solid" class="size-6" />
            </div>
            <p class="font-black text-[11px] uppercase tracking-widest leading-relaxed mt-1"><%= msg %></p>
          </div>
        <% end %>

        <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
          <div class="flex items-start gap-4 bg-success/90 backdrop-blur-md text-success-content p-5 rounded-2xl shadow-2xl shadow-success/30 animate-in slide-in-from-right-8 duration-500 pointer-events-auto">
            <div class="p-1.5 bg-success-content/20 rounded-xl shrink-0">
              <.icon name="hero-check-circle-solid" class="size-6" />
            </div>
            <p class="font-black text-[11px] uppercase tracking-widest leading-relaxed mt-1"><%= msg %></p>
          </div>
        <% end %>
      </div>

      <%!-- BARRA SUPERIOR DE NAVEGACIÓN CRISTAL --%>
      <nav class="bg-base-100/80 backdrop-blur-2xl border-b border-base-200/60 sticky top-0 z-40 shadow-sm mb-8 md:mb-12 transition-all">
        <div class="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <.link navigate={~p"/cliente/sorteos"} class="p-3 bg-base-200/50 hover:bg-primary/10 hover:text-primary rounded-2xl transition-all duration-300 group flex items-center gap-3">
            <.icon name="hero-arrow-left-solid" class="size-5 group-hover:-translate-x-1 transition-transform" />
            <span class="hidden md:inline font-black text-[10px] uppercase tracking-widest">Volver a Sorteos</span>
          </.link>

          <div class="flex items-center gap-4 md:gap-6">
             <button phx-click="abrir_historial" class="flex flex-col items-end px-4 border-r border-base-300/50 hover:opacity-70 transition-opacity text-right group">
                <p class="text-[9px] font-black opacity-40 uppercase tracking-[0.2em]">Saldo Disponible</p>
                <p class="text-xl md:text-2xl font-black leading-none italic text-success group-hover:scale-105 transition-transform">
                  $<%= @balance.saldo %>
                </p>
             </button>
             <button phx-click="abrir_modal" class="btn btn-primary h-12 px-6 rounded-2xl font-black text-[10px] uppercase tracking-widest shadow-lg shadow-primary/20 hover:-translate-y-1 hover:shadow-primary/40 transition-all gap-2">
                <.icon name="hero-plus-circle-solid" class="size-5" />
                <span class="hidden md:inline">Recargar</span>
             </button>
          </div>
        </div>
      </nav>

      <div class="max-w-7xl mx-auto px-4 grid grid-cols-1 lg:grid-cols-4 gap-8 md:gap-12 relative">
        <div class="absolute top-1/4 left-1/2 -translate-x-1/2 w-[800px] h-[500px] bg-primary/5 rounded-full blur-[120px] pointer-events-none"></div>

        <%!-- MENÚ LATERAL --%>
        <div class="lg:col-span-1">
          <div class="bg-base-100/80 backdrop-blur-xl p-6 rounded-[2.5rem] shadow-xl border border-base-200/60 sticky top-32">
            <h3 class="opacity-40 text-[10px] uppercase font-black tracking-[0.2em] px-4 mb-4">Ajustes de Cuenta</h3>
            <ul class="flex flex-col gap-2">
              <li>
                <button phx-click="set_seccion" phx-value-sec="info"
                  class={["w-full flex items-center gap-4 px-5 py-4 rounded-2xl font-black text-[11px] uppercase tracking-widest transition-all duration-300", @seccion_activa == "info" && "bg-primary text-primary-content shadow-lg shadow-primary/30", @seccion_activa != "info" && "text-base-content/50 hover:bg-base-200/80 hover:text-base-content"]}>
                  <.icon name="hero-user-solid" class="size-5" /> Mi Perfil
                </button>
              </li>
              <li>
                <button phx-click="set_seccion" phx-value-sec="seguridad"
                  class={["w-full flex items-center gap-4 px-5 py-4 rounded-2xl font-black text-[11px] uppercase tracking-widest transition-all duration-300", @seccion_activa == "seguridad" && "bg-base-content text-base-100 shadow-lg shadow-base-content/20", @seccion_activa != "seguridad" && "text-base-content/50 hover:bg-base-200/80 hover:text-base-content"]}>
                  <.icon name="hero-shield-check-solid" class="size-5" /> Seguridad
                </button>
                <%!-- Agrega después del botón "Seguridad" en el <ul> del menú --%>
    <li>
    <button phx-click="set_seccion" phx-value-sec="historial_tickets"
    class={["w-full flex items-center gap-4 px-5 py-4 rounded-2xl font-black text-[11px] uppercase tracking-widest transition-all duration-300",
      @seccion_activa == "historial_tickets" && "bg-info text-info-content shadow-lg shadow-info/30",
      @seccion_activa != "historial_tickets" && "text-base-content/50 hover:bg-base-200/80 hover:text-base-content"]}>
    <.icon name="hero-ticket-solid" class="size-5" /> Mis Tickets
    </button>
    </li>
    <li>
    <button phx-click="set_seccion" phx-value-sec="historial_sorteos"
    class={["w-full flex items-center gap-4 px-5 py-4 rounded-2xl font-black text-[11px] uppercase tracking-widest transition-all duration-300",
      @seccion_activa == "historial_sorteos" && "bg-warning text-warning-content shadow-lg shadow-warning/30",
      @seccion_activa != "historial_sorteos" && "text-base-content/50 hover:bg-base-200/80 hover:text-base-content"]}>
    <.icon name="hero-trophy-solid" class="size-5" /> Mis Sorteos
    </button>
    </li>
              </li>
            </ul>
          </div>
        </div>

        <%!-- CONTENIDO PRINCIPAL --%>
        <div class="lg:col-span-3 space-y-8 relative z-10">
          <%= if @seccion_activa == "info" do %>
            <div class="relative bg-base-100/90 backdrop-blur-3xl rounded-[3rem] shadow-2xl border border-base-200/60 overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-500">
              <div class="relative p-8 md:p-12 border-b border-base-200/60 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-6 overflow-hidden">
                <div class="absolute inset-0 bg-gradient-to-br from-primary/5 to-transparent pointer-events-none"></div>
                <div class="relative z-10">
                  <h2 class="text-3xl md:text-4xl font-black italic uppercase tracking-tighter text-base-content drop-shadow-sm">Información Personal</h2>
                  <div class="flex items-center gap-3 mt-3 bg-base-200/50 w-fit px-4 py-1.5 rounded-full border border-base-300/50">
                    <div class="size-2 rounded-full bg-success shadow-[0_0_8px_rgba(0,255,0,0.8)] animate-pulse"></div>
                    <span class="text-[9px] font-black text-base-content/60 uppercase tracking-widest">Cuenta Verificada</span>
                  </div>
                </div>
                <div class="relative group z-10">
                  <div class="absolute -inset-2 bg-primary/20 rounded-[2rem] blur-xl opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
                  <div class="relative bg-gradient-to-br from-base-200 to-base-300 text-base-content rounded-[2rem] w-24 h-24 flex items-center justify-center border border-base-100 shadow-inner group-hover:scale-105 transition-transform duration-500">
                    <.icon name="hero-user-solid" class="size-12 opacity-80" />
                  </div>
                </div>
              </div>

              <div class="p-4 md:p-6 divide-y divide-base-200/60">
                <%!-- Nombre --%>
                <div class="p-6 flex flex-col md:flex-row md:items-center justify-between gap-6 hover:bg-base-200/30 transition-colors rounded-[2rem] group">
                  <div class="md:w-1/3"><p class="font-black text-[10px] uppercase tracking-[0.2em] opacity-40">Nombre Completo</p></div>
                  <div class="flex-1">
                    <%= if @editando_campo == "nombre" do %>
                      <form phx-submit="guardar_cambios" class="flex flex-col sm:flex-row gap-3">
                        <input type="hidden" name="campo" value="nombre" />
                        <input name="valor" value={@usuario.nombre} class="input input-bordered bg-base-100 focus:border-primary w-full max-w-sm rounded-xl" autofocus />
                        <div class="flex gap-2">
                          <button class="btn btn-primary rounded-xl px-6 shadow-md shadow-primary/20"><.icon name="hero-check" class="size-5" /></button>
                          <button type="button" phx-click="cancelar_edicion" class="btn btn-ghost bg-base-200 rounded-xl px-4 hover:text-error"><.icon name="hero-x-mark" class="size-5" /></button>
                        </div>
                      </form>
                    <% else %>
                      <p class="text-xl md:text-2xl font-black text-base-content italic"><%= @usuario.nombre %></p>
                    <% end %>
                  </div>
                  <%= if @editando_campo != "nombre" do %>
                    <button phx-click="editar" phx-value-campo="nombre" class="btn btn-ghost btn-sm bg-base-200/50 hover:bg-primary/10 hover:text-primary rounded-xl font-black text-[10px] uppercase tracking-widest opacity-0 group-hover:opacity-100 transition-all">Editar</button>
                  <% end %>
                </div>

                <%!-- Email --%>
                <div class="p-6 flex flex-col md:flex-row md:items-center justify-between gap-6 hover:bg-base-200/30 transition-colors rounded-[2rem] group">
                  <div class="md:w-1/3"><p class="font-black text-[10px] uppercase tracking-[0.2em] opacity-40">Correo Electrónico</p></div>
                  <div class="flex-1">
                    <%= if @editando_campo == "email" do %>
                      <form phx-submit="guardar_cambios" class="flex flex-col sm:flex-row gap-3">
                        <input type="hidden" name="campo" value="email" />
                        <input type="email" name="valor" value={@usuario.email} class="input input-bordered bg-base-100 focus:border-primary w-full max-w-sm rounded-xl" autofocus />
                        <div class="flex gap-2">
                          <button class="btn btn-primary rounded-xl px-6 shadow-md shadow-primary/20"><.icon name="hero-check" class="size-5" /></button>
                          <button type="button" phx-click="cancelar_edicion" class="btn btn-ghost bg-base-200 rounded-xl px-4 hover:text-error"><.icon name="hero-x-mark" class="size-5" /></button>
                        </div>
                      </form>
                    <% else %>
                      <p class="text-lg md:text-xl font-bold text-base-content/80"><%= @usuario.email %></p>
                    <% end %>
                  </div>
                  <%= if @editando_campo != "email" do %>
                    <button phx-click="editar" phx-value-campo="email" class="btn btn-ghost btn-sm bg-base-200/50 hover:bg-primary/10 hover:text-primary rounded-xl font-black text-[10px] uppercase tracking-widest opacity-0 group-hover:opacity-100 transition-all">Editar</button>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <%= if @seccion_activa == "seguridad" do %>
            <div class="relative bg-base-100/90 backdrop-blur-3xl rounded-[3rem] shadow-2xl border border-base-200/60 overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-500">
              <div class="relative p-8 md:p-12 border-b border-base-200/60 overflow-hidden">
                <div class="absolute inset-0 bg-gradient-to-br from-base-content/5 to-transparent pointer-events-none"></div>
                <div class="relative z-10">
                  <h2 class="text-3xl md:text-4xl font-black italic uppercase tracking-tighter text-base-content drop-shadow-sm">Seguridad</h2>
                  <p class="text-[11px] font-black uppercase tracking-widest text-base-content/40 mt-3">Protege tu acceso a la plataforma.</p>
                </div>
              </div>
              <%!-- ═══════════════════════════════════ --%>
    <%!-- SECCIÓN: MIS TICKETS               --%>
    <%!-- ═══════════════════════════════════ --%>
    <%= if @seccion_activa == "historial_tickets" do %>
    <div class="relative bg-base-100/90 backdrop-blur-3xl rounded-[3rem] shadow-2xl border border-base-200/60 overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-500">
    <div class="relative p-8 md:p-12 border-b border-base-200/60 overflow-hidden">
      <div class="absolute inset-0 bg-gradient-to-br from-info/5 to-transparent pointer-events-none"></div>
      <div class="relative z-10">
        <h2 class="text-3xl md:text-4xl font-black italic uppercase tracking-tighter">Mis Tickets</h2>
        <p class="text-[11px] font-black uppercase tracking-widest text-base-content/40 mt-3">
          Tickets activos y devueltos
        </p>
      </div>
    </div>

    <div class="p-6 md:p-10 space-y-4">
      <%= if Enum.empty?(@tickets_usuario) do %>
        <div class="flex flex-col items-center justify-center py-16 text-base-content/30">
          <.icon name="hero-ticket-solid" class="size-12 mb-3 opacity-20" />
          <p class="font-black text-[11px] uppercase tracking-widest">Aún no has comprado tickets</p>
        </div>
      <% else %>
        <%= for ticket <- @tickets_usuario do %>
          <div class={[
            "flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 p-5 rounded-[2rem] border transition-all",
            ticket.estado == "vendido" && "bg-base-200/40 border-base-300/40",
            ticket.estado == "disponible" && "bg-success/5 border-success/20 opacity-50"
          ]}>
            <div class="flex items-center gap-4">
              <div class={[
                "size-14 rounded-2xl flex items-center justify-center font-black text-xl shadow-inner",
                ticket.estado == "vendido" && "bg-primary/10 text-primary",
                ticket.estado == "disponible" && "bg-base-300/50 text-base-content/40"
              ]}>
              </div>
              <div>
                <p class="font-black text-base-content"><%= ticket.sorteo.titulo %></p>
                <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 mt-0.5">
                  $<%= ticket.sorteo.precio_ticket %> · <%= Calendar.strftime(ticket.inserted_at, "%d/%m/%Y") %>
                </p>
                <div class={[
                  "inline-flex items-center gap-1 mt-1 px-2 py-0.5 rounded-lg text-[9px] font-black uppercase tracking-widest",
                  ticket.sorteo.estado == "activo" && "bg-success/10 text-success",
                  ticket.sorteo.estado == "finalizado" && "bg-base-300/50 text-base-content/40",
                  ticket.sorteo.estado == "cancelado" && "bg-error/10 text-error"
                ]}>
                  Sorteo: <%= ticket.sorteo.estado %>
                </div>
              </div>
            </div>

            <%= if ticket.estado == "vendido" and ticket.sorteo.estado == "activo" do %>
              <button
                phx-click="devolver_ticket"
                phx-value-ticket_id={ticket.id}
                data-confirm="¿Seguro que quieres devolver el ticket ##{ticket.numero}? Se te reembolsará $#{ticket.sorteo.precio_ticket}."
                class="btn btn-ghost btn-sm bg-error/5 hover:bg-error/10 text-error border border-error/20 rounded-2xl font-black text-[9px] uppercase tracking-widest gap-2 shrink-0">
                <.icon name="hero-arrow-uturn-left-solid" class="size-4" />
                Devolver
              </button>
            <% end %>

            <%= if ticket.sorteo.estado == "finalizado" do %>
              <% es_ganador = ticket.numero in (ticket.sorteo.numeros_ganadores || []) %>
              <div class={[
                "px-4 py-2 rounded-2xl font-black text-[10px] uppercase tracking-widest shrink-0",
                es_ganador && "bg-warning/10 text-warning border border-warning/20",
                not es_ganador && "bg-base-300/30 text-base-content/30 border border-base-300/20"
              ]}>
                <%= if es_ganador, do: "🏆 Ganador", else: "Sin suerte" %>
              </div>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    </div>
    <% end %>

    <%!-- ═══════════════════════════════════ --%>
    <%!-- SECCIÓN: MIS SORTEOS               --%>
    <%!-- ═══════════════════════════════════ --%>
    <%= if @seccion_activa == "historial_sorteos" do %>
    <div class="relative bg-base-100/90 backdrop-blur-3xl rounded-[3rem] shadow-2xl border border-base-200/60 overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-500">
    <div class="relative p-8 md:p-12 border-b border-base-200/60 overflow-hidden">
      <div class="absolute inset-0 bg-gradient-to-br from-warning/5 to-transparent pointer-events-none"></div>
      <div class="relative z-10">
        <h2 class="text-3xl md:text-4xl font-black italic uppercase tracking-tighter">Mis Sorteos</h2>
        <p class="text-[11px] font-black uppercase tracking-widest text-base-content/40 mt-3">
          Resumen de cada sorteo en que participaste
        </p>
      </div>
    </div>

    <div class="p-6 md:p-10 space-y-6">
      <%
        sorteos_agrupados =
          @tickets_usuario
          |> Enum.group_by(& &1.sorteo_id)
          |> Enum.map(fn {_id, tickets} ->
            sorteo = hd(tickets).sorteo
            tickets_comprados = Enum.filter(tickets, & &1.estado == "vendido")
            cantidad = length(tickets_comprados)
            gasto = Decimal.mult(sorteo.precio_ticket, Decimal.new(cantidad))
            es_ganador = Enum.any?(tickets_comprados, & &1.numero in (sorteo.numeros_ganadores || []))
            %{sorteo: sorteo, tickets: tickets_comprados, cantidad: cantidad, gasto: gasto, es_ganador: es_ganador}
          end)
          |> Enum.sort_by(& &1.sorteo.inserted_at, {:desc, NaiveDateTime})
      %>

      <%= if Enum.empty?(sorteos_agrupados) do %>
        <div class="flex flex-col items-center justify-center py-16 text-base-content/30">
          <.icon name="hero-trophy-solid" class="size-12 mb-3 opacity-20" />
          <p class="font-black text-[11px] uppercase tracking-widest">No has participado en sorteos aún</p>
        </div>
      <% else %>
        <%= for item <- sorteos_agrupados do %>
          <div class={[
            "p-6 rounded-[2.5rem] border transition-all",
            item.sorteo.estado == "finalizado" && item.es_ganador && "bg-warning/5 border-warning/20",
            item.sorteo.estado == "finalizado" && not item.es_ganador && "bg-base-200/30 border-base-300/30",
            item.sorteo.estado == "activo" && "bg-primary/5 border-primary/20",
            item.sorteo.estado == "cancelado" && "bg-error/5 border-error/20"
          ]}>
            <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-4">
              <div>
                <div class="flex items-center gap-3 flex-wrap">
                  <h3 class="font-black text-xl italic"><%= item.sorteo.titulo %></h3>
                  <div class={[
                    "px-3 py-1 rounded-xl text-[9px] font-black uppercase tracking-widest border",
                    item.sorteo.estado == "activo" && "bg-success/10 text-success border-success/20",
                    item.sorteo.estado == "finalizado" && "bg-base-300/30 text-base-content/40 border-base-300/20",
                    item.sorteo.estado == "cancelado" && "bg-error/10 text-error border-error/20"
                  ]}>
                    <%= item.sorteo.estado %>
                  </div>
                  <%= if item.sorteo.estado == "finalizado" do %>
                    <div class={[
                      "px-3 py-1 rounded-xl text-[9px] font-black uppercase tracking-widest border",
                      item.es_ganador && "bg-warning/10 text-warning border-warning/20",
                      not item.es_ganador && "bg-base-300/20 text-base-content/30 border-transparent"
                    ]}>
                      <%= if item.es_ganador, do: "🏆 Ganaste", else: "Sin premio" %>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
              <div class="bg-base-100/50 p-3 rounded-2xl border border-base-200/40">
                <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40">Tickets</p>
                <p class="text-2xl font-black italic"><%= item.cantidad %></p>
              </div>
              <div class="bg-base-100/50 p-3 rounded-2xl border border-base-200/40">
                <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40">Invertido</p>
                <p class="text-2xl font-black italic text-error">-$<%= item.gasto %></p>
              </div>
              <%= if item.sorteo.estado == "cancelado" do %>
                <div class="bg-info/5 p-3 rounded-2xl border border-info/20 col-span-2">
                  <p class="text-[9px] font-black uppercase tracking-widest text-info/60">Reembolsado</p>
                  <p class="text-2xl font-black italic text-info">+$<%= item.gasto %></p>
                </div>
              <% end %>
              <%= if item.sorteo.estado == "finalizado" do %>
                <%
                  trans_premios = Enum.filter(@transacciones, fn t ->
                    t.tipo == "premio" and t.sorteo_id == item.sorteo.id
                  end)
                  total_premio = Enum.reduce(trans_premios, Decimal.new(0), fn t, acc ->
                    Decimal.add(acc, t.monto)
                  end)
                %>
                <div class={[
                  "p-3 rounded-2xl border col-span-2 md:col-span-2",
                  item.es_ganador && "bg-warning/5 border-warning/20",
                  not item.es_ganador && "bg-base-200/20 border-transparent"
                ]}>
                  <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40">Premio recibido</p>
                  <p class={["text-2xl font-black italic", item.es_ganador && "text-warning", not item.es_ganador && "text-base-content/20"]}>
                    <%= if item.es_ganador, do: "+$#{total_premio}", else: "$0" %>
                  </p>
                </div>
              <% end %>
            </div>

        <%!-- Numeros jugados --%>            <div class="mt-4 flex flex-wrap gap-2">
              <%= for t <- item.tickets do %>
                <span class={[
                  "inline-flex items-center justify-center size-10 rounded-xl font-black text-sm border",
                  t.numero in (item.sorteo.numeros_ganadores || []) && "bg-warning text-warning-content border-warning shadow-md",
                  t.numero not in (item.sorteo.numeros_ganadores || []) && "bg-base-200/60 text-base-content/50 border-base-300/30"
                ]}>
                  <%= t.numero %>
                </span>
              <% end %>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    </div>
    <% end %>

              <div class="p-6 md:p-10">
                <div class="flex flex-col md:flex-row items-start md:items-center justify-between bg-base-200/50 border border-base-300/50 p-8 rounded-[2.5rem] shadow-inner gap-6">
                  <div class="flex items-center gap-5">
                    <div class="p-4 bg-base-100 rounded-2xl text-base-content border border-base-200 shadow-sm">
                        <.icon name="hero-key-solid" class="size-8" />
                    </div>
                    <div>
                      <p class="font-black text-xl italic">Contraseña</p>
                      <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 mt-1">Protección activa</p>
                    </div>
                  </div>
                  <div class="w-full md:w-auto">
                    <%= if @editando_campo == "password" do %>
                      <form phx-submit="guardar_cambios" class="flex flex-col sm:flex-row gap-3 w-full md:w-80">
                        <input type="hidden" name="campo" value="password" />
                        <input type="password" name="valor" placeholder="Nueva clave..." class="input input-bordered bg-base-100 focus:border-base-content w-full rounded-xl" autofocus required />
                        <div class="flex gap-2">
                          <button class="btn btn-neutral rounded-xl px-6"><.icon name="hero-check" class="size-5" /></button>
                          <button type="button" phx-click="cancelar_edicion" class="btn btn-ghost bg-base-100 rounded-xl px-4 hover:text-error"><.icon name="hero-x-mark" class="size-5" /></button>
                        </div>
                      </form>
                    <% else %>
                      <button phx-click="editar" phx-value-campo="password" class="btn btn-neutral h-14 rounded-2xl font-black text-[10px] uppercase tracking-widest px-8 shadow-xl hover:-translate-y-1 transition-all w-full md:w-auto">
                        Cambiar Clave
                      </button>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <%!-- ========================================== --%>
      <%!-- MODAL HISTORIAL DE FONDOS Y RENDIMIENTO    --%>
      <%!-- ========================================== --%>
      <%= if @show_historial_modal do %>
        <div class="fixed inset-0 z-[100] flex items-center justify-center px-4">
          <div phx-click="cerrar_historial" class="absolute inset-0 bg-base-300/80 backdrop-blur-md"></div>

          <div class="relative bg-base-100/95 backdrop-blur-3xl border border-base-200/60 rounded-[3rem] p-6 md:p-10 w-full max-w-lg shadow-2xl animate-in fade-in zoom-in-95 duration-200">
            <button phx-click="cerrar_historial" class="absolute top-6 right-6 p-2 bg-base-200/50 hover:bg-error/10 hover:text-error rounded-xl transition-colors">
              <.icon name="hero-x-mark-solid" class="size-6" />
            </button>

            <div class="text-center mb-8">
              <div class="inline-flex p-3 bg-primary/10 text-primary rounded-2xl mb-4 shadow-inner">
                <.icon name="hero-chart-bar-solid" class="size-8" />
              </div>
              <h3 class="font-black text-2xl md:text-3xl text-base-content uppercase italic tracking-tighter">Mis Fondos</h3>
              <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 mt-1">Resumen financiero de tu cuenta</p>
            </div>

            <div class="bg-gradient-to-br from-primary/10 to-primary/5 border border-primary/20 rounded-[2rem] p-6 mb-6 flex items-center justify-between">
              <div>
                <p class="text-[10px] font-black uppercase tracking-widest text-primary/70">Saldo Disponible</p>
                <p class="text-4xl font-black italic text-primary leading-none mt-1">
                  $<%= @balance.saldo %>
                </p>
              </div>
              <div class="p-4 bg-primary/10 rounded-2xl">
                <.icon name="hero-wallet-solid" class="size-8 text-primary" />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-3 mb-4">
              <div class="bg-base-200/50 p-4 rounded-2xl border border-base-300/30 flex flex-col gap-1">
                <span class="text-[9px] font-black uppercase tracking-widest text-base-content/40 flex items-center gap-1">
                  <.icon name="hero-ticket-solid" class="size-3" /> Tickets
                </span>
                <span class="text-2xl font-black italic text-base-content"><%= @balance.tickets %></span>
              </div>
              <div class="bg-base-200/50 p-4 rounded-2xl border border-base-300/30 flex flex-col gap-1">
                <span class="text-[9px] font-black uppercase tracking-widest text-base-content/40 flex items-center gap-1">
                  <.icon name="hero-sparkles-solid" class="size-3" /> Sorteos
                </span>
                <span class="text-2xl font-black italic text-base-content"><%= @balance.sorteos %></span>
              </div>
            </div>

            <div class="space-y-2 mb-4">
              <div class="bg-base-200/40 p-4 rounded-2xl border border-base-300/30 flex justify-between items-center">
                <span class="text-[11px] font-black uppercase tracking-widest text-base-content/50 flex items-center gap-2">
                  <.icon name="hero-arrow-down-circle-solid" class="size-4 text-info" /> Total Recargado
                </span>
                <span class="font-black text-base-content">+$<%= @balance.recargado %></span>
              </div>

              <div class="bg-error/5 p-4 rounded-2xl border border-error/15 flex justify-between items-center">
                <span class="text-[11px] font-black uppercase tracking-widest text-error/70 flex items-center gap-2">
                  <.icon name="hero-shopping-cart-solid" class="size-4" /> Gastado en Tickets
                </span>
                <span class="font-black text-error">-$<%= @balance.gastado %></span>
              </div>

              <div class="bg-warning/5 p-4 rounded-2xl border border-warning/15 flex justify-between items-center">
                <span class="text-[11px] font-black uppercase tracking-widest text-warning/70 flex items-center gap-2">
                  <.icon name="hero-trophy-solid" class="size-4" /> Ganado en Premios
                </span>
                <span class="font-black text-warning">+$<%= @balance.ganado %></span>
              </div>
            </div>

            <div class={[
              "p-5 rounded-2xl border flex items-center justify-between",
              if(@balance.es_ganancia,
                do: "bg-success/10 border-success/20",
                else: "bg-error/10 border-error/20")
            ]}>
              <div>
                <p class="text-[10px] font-black uppercase tracking-widest text-base-content/50">Rendimiento Neto</p>
                <p class="text-[9px] text-base-content/30 mt-0.5 uppercase tracking-wider">Premios vs Tickets comprados</p>
              </div>
              <div class="text-right">
                <p class={["text-3xl font-black italic", if(@balance.es_ganancia, do: "text-success", else: "text-error")]}>
                  <%= if @balance.es_ganancia, do: "+", else: "" %>$<%= @balance.rendimiento %>
                </p>
                <p class={["text-[9px] font-black uppercase tracking-widest mt-0.5", if(@balance.es_ganancia, do: "text-success/60", else: "text-error/60")]}>
                  <%= if @balance.es_ganancia, do: "¡Vas ganando!", else: "Sigue intentando" %>
                </p>
              </div>
            </div>

          </div>
        </div>
      <% end %>

      <%!-- ========================================== --%>
      <%!-- MODAL DE RECARGA                           --%>
      <%!-- ========================================== --%>
      <%= if @show_modal do %>
        <div class="fixed inset-0 z-[100] flex items-center justify-center px-4">
          <div phx-click="cerrar_modal" class="absolute inset-0 bg-base-300/80 backdrop-blur-md"></div>
          <div class="relative bg-base-100/95 backdrop-blur-3xl border border-base-200/60 rounded-[3rem] p-6 md:p-10 w-full max-w-xl shadow-2xl animate-in fade-in zoom-in-95 duration-200">
            <button phx-click="cerrar_modal" class="absolute top-6 right-6 p-2 bg-base-200/50 hover:bg-error/10 hover:text-error rounded-xl transition-colors">
              <.icon name="hero-x-mark-solid" class="size-6" />
            </button>
            <div class="text-center mb-8">
              <div class="inline-flex p-3 bg-primary/10 text-primary rounded-2xl mb-4 shadow-inner">
                <.icon name="hero-wallet-solid" class="size-8" />
              </div>
              <h3 class="font-black text-2xl md:text-3xl text-base-content uppercase italic tracking-tighter">Cargar Saldo</h3>
            </div>

            <form phx-submit="confirmar_recarga" class="space-y-8">
              <div class="space-y-4">
                <div class="flex items-center gap-3">
                  <div class="h-6 w-1.5 bg-primary rounded-full"></div>
                  <h4 class="font-black text-[11px] uppercase tracking-[0.2em] text-base-content/60">1. Selecciona el monto</h4>
                </div>
                <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
                  <%= for amount <- [10000, 20000, 50000, 100000] do %>
                    <button type="button" phx-click="seleccionar_monto" phx-value-monto={amount}
                      class={["h-14 rounded-2xl font-black text-sm md:text-base italic transition-all border", @modo_monto == "rapido" && @monto_seleccionado == amount && "bg-primary text-primary-content border-primary shadow-lg shadow-primary/30 scale-[1.02]", !(@modo_monto == "rapido" && @monto_seleccionado == amount) && "bg-base-200/50 border-base-300/50 text-base-content/70 hover:bg-base-200"]}>
                      $<%= amount %>
                    </button>
                  <% end %>
                  <button type="button" phx-click="activar_manual"
                    class={["col-span-2 md:col-span-1 h-14 rounded-2xl font-black text-[11px] uppercase tracking-widest transition-all border flex items-center justify-center gap-2", @modo_monto == "manual" && "bg-secondary text-secondary-content border-secondary shadow-lg shadow-secondary/30 scale-[1.02]", @modo_monto != "manual" && "bg-base-200/50 border-base-300/50 text-base-content/70 hover:bg-base-200"]}>
                    <.icon name="hero-pencil-square-solid" class="size-4" /> Otro Valor
                  </button>
                </div>
                <%= if @modo_monto == "manual" do %>
                  <div class="pt-2 animate-in slide-in-from-top-2 duration-200">
                    <div class="relative">
                      <div class="absolute inset-y-0 left-5 flex items-center pointer-events-none">
                        <span class="text-secondary font-black text-xl">$</span>
                      </div>
                      <input type="number" name="monto_manual" placeholder="Monto a recargar..." class="input input-bordered bg-base-200/50 focus:bg-base-100 focus:border-secondary w-full text-xl font-black italic rounded-[1.5rem] h-16 pl-10 pr-6 transition-colors" autofocus required />
                    </div>
                  </div>
                <% end %>
              </div>

              <div class="space-y-4">
                <div class="flex items-center gap-3">
                  <div class="h-6 w-1.5 bg-primary rounded-full"></div>
                  <h4 class="font-black text-[11px] uppercase tracking-[0.2em] text-base-content/60">2. Método de pago</h4>
                </div>
                <div class="grid grid-cols-3 gap-3">
                  <%= for {m, icon, label} <- [{"pse", "hero-building-library-solid", "PSE"}, {"tarjeta", "hero-credit-card-solid", "Tarjeta"}, {"efectivo", "hero-banknotes-solid", "Efectivo"}] do %>
                    <button type="button" phx-click="seleccionar_metodo" phx-value-metodo={m}
                      class={["flex flex-col items-center justify-center gap-2 h-24 rounded-[1.5rem] border transition-all", @metodo_pago == m && "bg-base-content text-base-100 border-base-content shadow-lg shadow-base-content/20 scale-[1.02]", @metodo_pago != m && "bg-base-200/50 border-base-300/50 text-base-content/60 hover:bg-base-200"]}>
                      <.icon name={icon} class="size-7" />
                      <span class="font-black text-[10px] uppercase tracking-widest"><%= label %></span>
                    </button>
                  <% end %>
                </div>
              </div>

              <div class="pt-6 border-t border-base-200/60">
                <button type="submit" phx-disable-with="Procesando..." class="btn btn-primary h-16 w-full rounded-[1.5rem] text-sm font-black uppercase tracking-widest shadow-xl shadow-primary/30 hover:shadow-primary/50 hover:-translate-y-1 transition-all gap-3">
                  Pagar <%= if @modo_monto == "rapido", do: "$#{@monto_seleccionado}" %>
                  <.icon name="hero-arrow-right-circle-solid" class="size-6" />
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>

    </div>
    """
  end
end
