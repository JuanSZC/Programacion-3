defmodule AzarAppWeb.Cliente.SorteosLive do
  @moduledoc """
  Módulo AzarAppWeb.Cliente.SorteosLive: lógica relacionada con sorteoslive.
  """

  use AzarAppWeb, :live_view
  alias AzarApp.Sorteos
  alias AzarApp.Cuentas

  @impl true
  def mount(_params, session, socket) do
    usuario_id = session["usuario_id"]
    usuario = if usuario_id, do: Cuentas.obtener_usuario!(usuario_id), else: nil

    if connected?(socket) do
      if usuario_id, do: Phoenix.PubSub.subscribe(AzarApp.PubSub, "usuario:#{usuario_id}")
      Phoenix.PubSub.subscribe(AzarApp.PubSub, "sorteos")
    end

    sorteos_base = fetch_sorteos("actuales")

    {:ok,
     socket
     |> assign(usuario: usuario)
     |> assign(tab_activa: "actuales")
     |> assign(sorteos_base: sorteos_base)
     |> assign(filtros: filtros_default())
     |> assign(show_filtros: false)
     |> assign(sorteos: sorteos_base)
     |> assign(premios: calcular_premios(sorteos_base))}
  end

  @impl true
  def handle_event("cambiar_tab", %{"tab" => tab}, socket) do
    sorteos_base = fetch_sorteos(tab)
    sorteos = aplicar_filtros(sorteos_base, socket.assigns.filtros)
    {:noreply,
     socket
     |> assign(tab_activa: tab, sorteos_base: sorteos_base, sorteos: sorteos)
     |> assign(premios: calcular_premios(sorteos))}
  end

  @impl true
  def handle_event("toggle_filtros", _, socket) do
    {:noreply, assign(socket, :show_filtros, !socket.assigns.show_filtros)}
  end

  @impl true
  def handle_event("filtrar", params, socket) do
    filtros = %{
      mes:   Map.get(params, "mes", ""),
      tipo:  Map.get(params, "tipo", "todos"),
      orden: Map.get(params, "orden", "reciente")
    }
    sorteos = aplicar_filtros(socket.assigns.sorteos_base, filtros)
    {:noreply,
     socket
     |> assign(filtros: filtros, sorteos: sorteos)
     |> assign(premios: calcular_premios(sorteos))}
  end

  @impl true
  def handle_event("limpiar_filtros", _, socket) do
    filtros = filtros_default()
    sorteos = aplicar_filtros(socket.assigns.sorteos_base, filtros)
    {:noreply,
     socket
     |> assign(filtros: filtros, sorteos: sorteos)
     |> assign(premios: calcular_premios(sorteos))}
  end

  @impl true
  def handle_info(:forzar_logout, socket), do: {:noreply, push_navigate(socket, to: "/forzar_logout")}

  @impl true
  def handle_info(event, socket) when event in [:lista_actualizada, :sorteo_ejecutado, :ticket_comprado] do
    reload(socket)
  end

  @impl true
  def handle_info({event, _}, socket) when event in [:sorteo_creado, :sorteo_eliminado, :saved] do
    reload(socket)
  end

  defp reload(socket) do
    base = fetch_sorteos(socket.assigns.tab_activa)
    sorteos = aplicar_filtros(base, socket.assigns.filtros)
    {:noreply,
     socket
     |> assign(sorteos_base: base, sorteos: sorteos)
     |> assign(premios: calcular_premios(sorteos))}
  end


  defp fetch_sorteos("actuales"), do: Sorteos.list_sorteos_futuros()
  defp fetch_sorteos("pasados"), do: Sorteos.list_sorteos_pasados()

  defp calcular_premios(sorteos), do: Map.new(sorteos, &{&1.id, Sorteos.premio_actual(&1)})

  defp filtros_default, do: %{mes: "", tipo: "todos", orden: "reciente"}
  defp filtros_activos?(f), do: f != filtros_default()

  defp aplicar_filtros(sorteos, filtros) do
    sorteos
    |> filtrar_mes(filtros.mes)
    |> filtrar_tipo(filtros.tipo)
    |> ordenar(filtros.orden)
  end

  defp filtrar_mes(s, ""), do: s
  defp filtrar_mes(s, mes) do
    {m, _} = Integer.parse(mes)
    Enum.filter(s, &(&1.fecha_ejecucion && &1.fecha_ejecucion.month == m))
  end

  defp filtrar_tipo(s, "todos"), do: s
  defp filtrar_tipo(s, tipo), do: Enum.filter(s, &(&1.tipo_premio == tipo))

  defp ordenar(s, "reciente"), do: Enum.sort_by(s, & &1.inserted_at, {:desc, NaiveDateTime})
  defp ordenar(s, "fecha_asc"), do: Enum.sort_by(s, & &1.fecha_ejecucion, Date)
  defp ordenar(s, "fecha_desc"), do: Enum.sort_by(s, & &1.fecha_ejecucion, {:desc, Date})
  defp ordenar(s, "nombre_az"), do: Enum.sort_by(s, &String.downcase(&1.titulo))
  defp ordenar(s, "nombre_za"), do: Enum.sort_by(s, &String.downcase(&1.titulo), :desc)
  defp ordenar(s, "precio_asc"), do: Enum.sort_by(s, & &1.precio_ticket, Decimal)
  defp ordenar(s, "precio_desc"), do: Enum.sort_by(s, & &1.precio_ticket, {:desc, Decimal})
  defp ordenar(s, _), do: s

  @impl true
  def render(assigns) do
    ~H"""
    <nav class="bg-base-100/80 backdrop-blur-2xl border-b border-base-200/60 sticky top-0 z-50 shadow-sm">
      <div class="max-w-7xl mx-auto px-6 py-4 flex justify-between items-center">
        <div class="flex items-center gap-3">
          <div class="p-2.5 bg-gradient-to-br from-primary to-primary/80 rounded-[1rem] shadow-lg shadow-primary/30">
            <.icon name="hero-sparkles-solid" class="size-6 text-white" />
          </div>
          <span class="font-black text-2xl tracking-tighter uppercase italic text-base-content">
            Azar<span class="text-primary">App</span>
          </span>
        </div>
        <div class="flex items-center gap-3 md:gap-5">
          <%= if @usuario do %>
            <div class="flex items-center gap-4 bg-base-200/50 pl-5 pr-2 py-1.5 rounded-[1.25rem] border border-base-300/50 shadow-inner">
              <div class="flex flex-col items-end">
                <span class="text-[9px] font-black opacity-50 uppercase tracking-[0.25em]">Crédito</span>
                <span class="font-black text-success text-lg leading-none italic">$<%= @usuario.saldo_virtual %></span>
              </div>
              <div class="h-8 w-px bg-base-300/50 mx-1"></div>
              <.link navigate={~p"/cliente/perfil"} class="p-2 hover:bg-base-100 rounded-xl transition-colors text-base-content/70 hover:text-primary">
                <.icon name="hero-user-solid" class="size-6" />
              </.link>
            </div>
            <.link href={~p"/sesion"} method="delete"
              class="btn btn-ghost bg-error/5 hover:bg-error/10 text-error border-error/20 btn-sm md:h-12 md:px-5 rounded-[1.25rem] font-black gap-2">
              <span class="hidden md:inline text-[10px] uppercase tracking-widest">Cerrar Sesión</span>
              <.icon name="hero-arrow-right-on-rectangle-solid" class="size-5" />
            </.link>
          <% end %>
        </div>
      </div>
    </nav>

    <div class="p-4 md:p-8 lg:p-12 min-h-screen bg-gradient-to-b from-base-200/30 to-base-100 animate-in fade-in duration-700">
      <div class="max-w-7xl mx-auto">

        <%!-- HEADER CON TABS Y FILTRO --%>
        <header class="relative bg-base-100/90 backdrop-blur-3xl p-8 md:p-10 rounded-[3rem] shadow-2xl border border-base-200/60 overflow-hidden mb-8">
          <div class="absolute -inset-4 bg-gradient-to-r from-primary/10 via-transparent to-transparent blur-2xl opacity-60 pointer-events-none"></div>
          <div class="relative z-10 flex flex-col lg:flex-row justify-between items-center gap-6">
            <div class="text-center lg:text-left">
              <h1 class="text-4xl md:text-5xl font-black text-base-content tracking-tighter italic uppercase leading-none">
                Sorteos <span class="text-primary">Azar</span>
              </h1>
              <p class="text-[10px] font-black text-base-content/40 mt-3 uppercase tracking-[0.3em]">
                Tu próxima gran victoria comienza aquí
              </p>
            </div>

            <div class="flex items-center gap-3">
              <%!-- TABS --%>
              <div class="flex p-1.5 bg-base-200/80 backdrop-blur-md rounded-[1.5rem] border border-base-300/50 shadow-inner">
                <button phx-click="cambiar_tab" phx-value-tab="actuales"
                  class={["px-6 h-11 rounded-[1.25rem] font-black text-[11px] uppercase tracking-widest transition-all duration-300",
                    if(@tab_activa == "actuales", do: "bg-primary text-primary-content shadow-lg shadow-primary/30", else: "text-base-content/50 hover:text-base-content hover:bg-base-100/50")]}>
                  Disponibles
                </button>
                <button phx-click="cambiar_tab" phx-value-tab="pasados"
                  class={["px-6 h-11 rounded-[1.25rem] font-black text-[11px] uppercase tracking-widest transition-all duration-300",
                    if(@tab_activa == "pasados", do: "bg-base-content text-base-100 shadow-lg", else: "text-base-content/50 hover:text-base-content hover:bg-base-100/50")]}>
                  Finalizados
                </button>
              </div>

              <%!-- BOTÓN FILTRO --%>
              <button phx-click="toggle_filtros"
                class={[
                  "btn h-11 w-11 rounded-2xl border transition-all relative",
                  if(@show_filtros,
                    do: "btn-primary shadow-lg shadow-primary/20",
                    else: "bg-base-200/80 border-base-300/50 hover:border-primary/30 hover:bg-primary/5")
                ]}>
                <.icon name="hero-funnel-solid" class="size-4" />
                <%= if filtros_activos?(@filtros) do %>
                  <span class="absolute -top-1 -right-1 size-3 bg-warning rounded-full border-2 border-base-100 animate-pulse"></span>
                <% end %>
              </button>
            </div>
          </div>

          <%!-- PANEL FILTROS --%>
          <%= if @show_filtros do %>
            <form phx-change="filtrar" class="relative z-10 mt-6 pt-6 border-t border-base-200/60 animate-in slide-in-from-top-2 duration-200">
              <div class="grid grid-cols-3 gap-4">
                <div class="flex flex-col gap-1.5">
                  <label class="text-[9px] font-black uppercase tracking-widest text-base-content/40 ml-1">Mes</label>
                  <select name="mes" class="select select-bordered h-11 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-primary/30 font-bold text-sm">
                    <option value="">Todos los meses</option>
                    <%= for {nombre, num} <- meses() do %>
                      <option value={num} selected={@filtros.mes == "#{num}"}><%= nombre %></option>
                    <% end %>
                  </select>
                </div>
                <div class="flex flex-col gap-1.5">
                  <label class="text-[9px] font-black uppercase tracking-widest text-base-content/40 ml-1">Tipo</label>
                  <select name="tipo" class="select select-bordered h-11 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-primary/30 font-bold text-sm">
                    <option value="todos" selected={@filtros.tipo == "todos"}>Todos</option>
                    <option value="fijo" selected={@filtros.tipo == "fijo"}>Premio Fijo</option>
                    <option value="acumulado" selected={@filtros.tipo == "acumulado"}>Acumulado</option>
                  </select>
                </div>
                <div class="flex flex-col gap-1.5">
                  <label class="text-[9px] font-black uppercase tracking-widest text-base-content/40 ml-1">Ordenar</label>
                  <select name="orden" class="select select-bordered h-11 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-primary/30 font-bold text-sm">
                    <option value="reciente" selected={@filtros.orden == "reciente"}>Más reciente</option>
                    <option value="fecha_asc" selected={@filtros.orden == "fecha_asc"}>Fecha ↑</option>
                    <option value="fecha_desc" selected={@filtros.orden == "fecha_desc"}>Fecha ↓</option>
                    <option value="nombre_az" selected={@filtros.orden == "nombre_az"}>Nombre A→Z</option>
                    <option value="nombre_za" selected={@filtros.orden == "nombre_za"}>Nombre Z→A</option>
                    <option value="precio_asc" selected={@filtros.orden == "precio_asc"}>Menor precio</option>
                    <option value="precio_desc" selected={@filtros.orden == "precio_desc"}>Mayor precio</option>
                  </select>
                </div>
              </div>
              <%= if filtros_activos?(@filtros) do %>
                <div class="mt-3 flex justify-end">
                  <button type="button" phx-click="limpiar_filtros"
                    class="btn btn-ghost btn-sm rounded-xl font-black text-[9px] uppercase tracking-widest text-error hover:bg-error/10 gap-1.5">
                    <.icon name="hero-x-mark-solid" class="size-3.5" /> Limpiar filtros
                  </button>
                </div>
              <% end %>
            </form>
          <% end %>
        </header>

        <%!-- SORTEOS --%>
        <%= if Enum.empty?(@sorteos) do %>
          <div class="relative flex flex-col items-center justify-center py-32 bg-base-100/50 rounded-[4rem] border-2 border-dashed border-base-300/50">
            <div class="p-8 bg-base-200/50 rounded-[2.5rem] mb-6">
              <.icon name="hero-funnel-solid" class="size-16 text-base-content/20" />
            </div>
            <h3 class="text-2xl font-black text-base-content/30 tracking-tighter italic uppercase">Sin resultados</h3>
            <p class="text-[10px] font-black uppercase tracking-widest text-base-content/20 mt-3">Ajusta los filtros</p>
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
                      if(sorteo.tipo_premio == "fijo", do: "bg-warning/10 text-warning border-warning/20", else: "bg-info/10 text-info border-info/20")
                    ]}>
                      <.icon name={if sorteo.tipo_premio == "fijo", do: "hero-lock-closed-solid", else: "hero-arrow-trending-up-solid"} class="size-3" />
                      <%= if sorteo.tipo_premio == "fijo", do: "Premio Fijo", else: "Acumulado" %>
                    </div>
                    <div class="bg-primary/10 text-primary p-2.5 rounded-2xl group-hover:rotate-12 transition-transform">
                      <.icon name="hero-bolt-solid" class="size-5" />
                    </div>
                  </div>
                  <h2 class="text-3xl font-black uppercase tracking-tighter mb-3 italic leading-tight text-base-content group-hover:text-primary transition-colors">
                    <%= sorteo.titulo %>
                  </h2>
                  <p class="text-base-content/50 text-sm font-medium leading-relaxed flex-1"><%= sorteo.descripcion %></p>
                  <%= if sorteo.estado == "finalizado" and not Enum.empty?(sorteo.numeros_ganadores || []) do %>
                    <div class="mt-6 flex items-center gap-4 bg-warning/10 border border-warning/20 rounded-2xl px-5 py-4">
                      <div class="p-2 bg-warning/20 rounded-xl shrink-0">
                        <.icon name="hero-trophy-solid" class="size-5 text-warning" />
                      </div>
                      <div>
                        <p class="text-[9px] font-black uppercase tracking-widest text-warning/70">Número Ganador</p>
                        <p class="text-2xl font-black italic text-warning leading-none mt-0.5">
                        </p>
                      </div>
                    </div>
                  <% end %>
                  <div class="mt-6 pt-6 border-t border-base-200/60 flex items-end justify-between gap-4">
                    <div class="flex flex-col gap-1.5">
                      <span class="text-[9px] font-black text-base-content/40 uppercase tracking-[0.2em]">
                        <%= if sorteo.tipo_premio == "fijo", do: "Premio", else: "Acumulado" %>
                      </span>
                      <p class="text-2xl font-black italic text-primary leading-none">$<%= @premios[sorteo.id] %></p>
                      <span class="text-[9px] font-black text-base-content/30 uppercase tracking-wider">Ticket: $<%= sorteo.precio_ticket %></span>
                    </div>
                    <%= if @tab_activa == "actuales" do %>
                      <.link navigate={~p"/cliente/sorteos/#{sorteo.id}"} class="btn btn-primary h-14 px-8 rounded-2xl font-black text-[10px] uppercase tracking-widest shadow-xl shadow-primary/20 hover:shadow-primary/40 hover:-translate-y-1 transition-all gap-2 shrink-0">
                        Jugar <.icon name="hero-arrow-right-circle-solid" class="size-5" />
                      </.link>
                    <% else %>
                      <.link navigate={~p"/cliente/sorteos/#{sorteo.id}"} class="btn btn-neutral h-14 px-8 rounded-2xl font-black text-[10px] uppercase tracking-widest shadow-xl hover:-translate-y-1 transition-all shrink-0">
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

  defp meses do
    [
      {"Enero", 1}, {"Febrero", 2}, {"Marzo", 3}, {"Abril", 4},
      {"Mayo", 5}, {"Junio", 6}, {"Julio", 7}, {"Agosto", 8},
      {"Septiembre", 9}, {"Octubre", 10}, {"Noviembre", 11}, {"Diciembre", 12}
    ]
  end
end
