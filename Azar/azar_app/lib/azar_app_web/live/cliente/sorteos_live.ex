defmodule AzarAppWeb.Cliente.SorteosLive do
  use AzarAppWeb, :live_view
  alias AzarApp.Sorteos
  alias AzarApp.Cuentas

  # MOUNT
  @impl true
  def mount(_params, session, socket) do
    usuario_id = session["usuario_id"]
    usuario = if usuario_id, do: Cuentas.obtener_usuario!(usuario_id), else: nil

    if connected?(socket) do
      if usuario_id, do: Phoenix.PubSub.subscribe(AzarApp.PubSub, "usuario:#{usuario_id}")
      Phoenix.PubSub.subscribe(AzarApp.PubSub, "sorteos")
    end

    sorteos = fetch_sorteos("actuales")

    {:ok,
     socket
     |> assign(usuario: usuario)
     |> assign(sorteos: sorteos)
     |> assign(premios: calcular_premios(sorteos))
     |> assign(tab_activa: "actuales")}
  end

  # EVENTS
  @impl true
  def handle_event("cambiar_tab", %{"tab" => tab}, socket) do
    sorteos = fetch_sorteos(tab)

    {:noreply,
     socket
     |> assign(sorteos: sorteos)
     |> assign(premios: calcular_premios(sorteos))
     |> assign(tab_activa: tab)}
  end

  # PUBSUB / INFO
  @impl true
  def handle_info(:forzar_logout, socket) do
    {:noreply, push_navigate(socket, to: "/forzar_logout")}
  end

  @impl true
  def handle_info(event, socket) when event in [:lista_actualizada, :sorteo_ejecutado, :ticket_comprado] do
    sorteos = fetch_sorteos(socket.assigns.tab_activa)
    {:noreply, assign(socket, sorteos: sorteos, premios: calcular_premios(sorteos))}
  end

  @impl true
  def handle_info({event, _sorteo}, socket) when event in [:sorteo_creado, :sorteo_eliminado, :saved] do
    sorteos = fetch_sorteos(socket.assigns.tab_activa)
    {:noreply, assign(socket, sorteos: sorteos, premios: calcular_premios(sorteos))}
  end

  # HELPERS
  defp fetch_sorteos("actuales"), do: Sorteos.list_sorteos_futuros()
  defp fetch_sorteos("pasados"), do: Sorteos.list_sorteos_pasados()

  defp calcular_premios(sorteos) do
    Map.new(sorteos, fn sorteo ->
      {sorteo.id, Sorteos.premio_actual(sorteo)}
    end)
  end

  # UI
  @impl true
  def render(assigns) do
    ~H"""
    <nav class="bg-base-100/80 backdrop-blur-2xl border-b border-base-200/60 sticky top-0 z-50 shadow-sm transition-all">
      <div class="max-w-7xl mx-auto px-6 py-4 flex justify-between items-center">
        <div class="flex items-center gap-3 group cursor-default">
          <div class="p-2.5 bg-gradient-to-br from-primary to-primary/80 rounded-[1rem] shadow-lg shadow-primary/30 group-hover:rotate-12 group-hover:scale-110 transition-all duration-300">
            <.icon name="hero-sparkles-solid" class="size-6 text-white" />
          </div>
          <span class="font-black text-2xl tracking-tighter uppercase italic drop-shadow-sm text-base-content">
            Azar<span class="text-primary">App</span>
          </span>
        </div>

        <div class="flex items-center gap-3 md:gap-5">
          <%= if @usuario do %>
            <div class="flex items-center gap-4 bg-base-200/50 pl-5 pr-2 py-1.5 rounded-[1.25rem] border border-base-300/50 shadow-inner group">
              <div class="flex flex-col items-end">
                <span class="text-[9px] font-black opacity-50 uppercase tracking-[0.25em]">Crédito Disponible</span>
                <span class="font-black text-success text-sm md:text-lg leading-none italic group-hover:scale-105 transition-transform">$<%= @usuario.saldo_virtual %></span>
              </div>
              <div class="h-8 w-[1px] bg-base-300/50 mx-1"></div>
              <.link navigate={~p"/cliente/perfil"} class="p-2 hover:bg-base-100 rounded-xl transition-colors text-base-content/70 hover:text-primary">
                <.icon name="hero-user-solid" class="size-6" />
              </.link>
            </div>
            <.link
              href={~p"/sesion"}
              method="delete"
              class="btn btn-ghost bg-error/5 hover:bg-error/10 text-error border-error/20 hover:border-error/30 btn-sm md:h-12 md:px-5 rounded-[1.25rem] font-black gap-2 transition-all"
            >
              <span class="hidden md:inline text-[10px] uppercase tracking-widest">Cerrar Sesión</span>
              <.icon name="hero-arrow-right-on-rectangle-solid" class="size-5" />
            </.link>
          <% end %>
        </div>
      </div>
    </nav>

    <div class="p-4 md:p-8 lg:p-12 min-h-screen bg-gradient-to-b from-base-200/30 to-base-100 animate-in fade-in zoom-in-95 duration-700">
      <div class="max-w-7xl mx-auto">

        <header class="relative bg-base-100/90 backdrop-blur-3xl p-8 md:p-12 rounded-[3rem] shadow-2xl border border-base-200/60 overflow-hidden mb-12 flex flex-col lg:flex-row justify-between items-center gap-8">
          <div class="absolute -inset-4 bg-gradient-to-r from-primary/10 via-transparent to-transparent blur-2xl opacity-60 pointer-events-none"></div>
          <div class="text-center lg:text-left relative z-10">
            <h1 class="text-4xl md:text-5xl lg:text-6xl font-black text-base-content tracking-tighter italic uppercase leading-none drop-shadow-sm">
              Sorteos <span class="text-primary">Azar</span>
            </h1>
            <p class="text-[10px] md:text-xs font-black text-base-content/40 mt-4 uppercase tracking-[0.3em]">
              Tu próxima gran victoria comienza aquí
            </p>
          </div>

          <div class="relative z-10 flex p-1.5 bg-base-200/80 backdrop-blur-md rounded-[1.5rem] border border-base-300/50 shadow-inner">
            <button
              phx-click="cambiar_tab" phx-value-tab="actuales"
              class={[
                "px-8 h-12 rounded-[1.25rem] font-black text-[11px] uppercase tracking-widest transition-all duration-300",
                if(@tab_activa == "actuales", do: "bg-primary text-primary-content shadow-lg shadow-primary/30", else: "text-base-content/50 hover:text-base-content hover:bg-base-100/50")
              ]}>
              Disponibles
            </button>
            <button
              phx-click="cambiar_tab" phx-value-tab="pasados"
              class={[
                "px-8 h-12 rounded-[1.25rem] font-black text-[11px] uppercase tracking-widest transition-all duration-300",
                if(@tab_activa == "pasados", do: "bg-base-content text-base-100 shadow-lg shadow-base-content/20", else: "text-base-content/50 hover:text-base-content hover:bg-base-100/50")
              ]}>
              Finalizados
            </button>
          </div>
        </header>

        <%= if Enum.empty?(@sorteos) do %>
          <div class="relative flex flex-col items-center justify-center py-32 bg-base-100/50 backdrop-blur-xl rounded-[4rem] border-2 border-dashed border-base-300/50 group">
            <div class="absolute inset-0 bg-gradient-to-b from-transparent to-base-200/20 rounded-[4rem] pointer-events-none"></div>
            <div class="p-8 bg-base-200/50 rounded-[2.5rem] mb-6 group-hover:scale-110 transition-transform duration-500 shadow-inner">
              <.icon name="hero-inbox-solid" class="size-16 text-base-content/20" />
            </div>
            <h3 class="text-2xl md:text-3xl font-black text-base-content/30 tracking-tighter italic uppercase text-center px-4">
              Aún no hay sorteos disponibles
            </h3>
            <p class="text-[10px] font-black uppercase tracking-widest text-base-content/20 mt-4">Vuelve a revisar pronto</p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <%= for sorteo <- @sorteos do %>
              <div class="card relative bg-base-100/90 backdrop-blur-xl shadow-xl border border-base-200/60 rounded-[3rem] hover:shadow-2xl hover:shadow-primary/10 hover:-translate-y-2 transition-all duration-500 group overflow-hidden flex flex-col">

                <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-primary/30 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>

                <div class="p-8 md:p-10 flex-1 flex flex-col">

                  <div class="flex justify-between items-center mb-6">
                    <div class={[
                      "inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl font-black text-[9px] uppercase tracking-widest border shadow-inner",
                      if(sorteo.tipo_premio == "fijo",
                        do: "bg-warning/10 text-warning border-warning/20",
                        else: "bg-info/10 text-info border-info/20")
                    ]}>
                      <.icon
                        name={if sorteo.tipo_premio == "fijo", do: "hero-lock-closed-solid", else: "hero-arrow-trending-up-solid"}
                        class="size-3"
                      />
                      <%= if sorteo.tipo_premio == "fijo", do: "Premio Fijo", else: "Acumulado" %>
                    </div>
                    <div class="bg-primary/10 text-primary p-2.5 rounded-2xl group-hover:rotate-12 transition-transform">
                      <.icon name="hero-bolt-solid" class="size-5" />
                    </div>
                  </div>

                  <h2 class="text-3xl font-black uppercase tracking-tighter mb-3 italic leading-tight text-base-content group-hover:text-primary transition-colors">
                    <%= sorteo.titulo %>
                  </h2>
                  <p class="text-base-content/50 text-sm font-medium leading-relaxed flex-1">
                    <%= sorteo.descripcion %>
                  </p>

                  <%= if sorteo.estado == "finalizado" and not Enum.empty?(sorteo.numeros_ganadores || []) do %>
                    <div class="mt-6 flex items-center gap-4 bg-warning/10 border border-warning/20 rounded-2xl px-5 py-4">
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

                  <div class="mt-6 pt-6 border-t border-base-200/60 flex items-end justify-between gap-4">
                    <div class="flex flex-col gap-1.5">
                      <div>
                        <span class="text-[9px] font-black text-base-content/40 uppercase tracking-[0.2em]">
                          <%= if sorteo.tipo_premio == "fijo", do: "Premio", else: "Acumulado" %>
                        </span>
                        <p class="text-2xl font-black italic text-primary leading-none mt-0.5">
                          $<%= @premios[sorteo.id] %>
                        </p>
                      </div>
                      <span class="text-[9px] font-black text-base-content/30 uppercase tracking-wider">
                        Ticket: $<%= sorteo.precio_ticket %>
                      </span>
                    </div>

                    <%= if @tab_activa == "actuales" do %>
                      <.link navigate={~p"/cliente/sorteos/#{sorteo.id}"} class="btn btn-primary h-14 px-8 rounded-2xl font-black text-[10px] uppercase tracking-widest shadow-xl shadow-primary/20 hover:shadow-primary/40 hover:-translate-y-1 transition-all gap-2 shrink-0">
                        Jugar
                        <.icon name="hero-arrow-right-circle-solid" class="size-5" />
                      </.link>
                    <% else %>
                      <.link navigate={~p"/cliente/sorteos/#{sorteo.id}"} class="btn btn-neutral h-14 px-8 rounded-2xl font-black text-[10px] uppercase tracking-widest shadow-xl shadow-neutral/20 hover:shadow-neutral/40 hover:-translate-y-1 transition-all shrink-0">
                        Ver Detalles
                      </.link>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
