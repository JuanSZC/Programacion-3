defmodule AzarAppWeb.Admin.DashboardLive do
  use AzarAppWeb, :live_view
  alias AzarApp.Reportes

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AzarApp.PubSub, "sorteos")
    end

    datos = Reportes.resumen_completo()

    {:ok,
     socket
     |> assign(:page_title, "Dashboard — Centro de Control")
     |> assign(:datos, datos)
     |> assign(:tab_activa, "general")}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cambiar_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :tab_activa, tab)}
  end

  @impl true
  def handle_info(:lista_actualizada, socket) do
    {:noreply, assign(socket, :datos, Reportes.resumen_completo())}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  # ==========================================
  # HELPERS PARA LA PLANTILLA
  # ==========================================

  defp fmt(nil), do: "0"
  defp fmt(%Decimal{} = d), do: d |> Decimal.round(0) |> Decimal.to_string() |> fmt_miles()
  defp fmt(n) when is_integer(n), do: Integer.to_string(n) |> fmt_miles()
  defp fmt(n) when is_float(n), do: :erlang.float_to_binary(n, decimals: 1)
  defp fmt(n), do: to_string(n)

  defp fmt_miles(str) do
    str
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end

  defp mes_nombre(n) do
    ~w(Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic) |> Enum.at(n - 1, "?")
  end

  defp pct(0, _), do: 0
  defp pct(_, 0), do: 0
  defp pct(parte, total), do: Float.round(parte / total * 100, 1)

  defp color_tipo("fijo"), do: "bg-warning/10 text-warning border-warning/20"
  defp color_tipo(_), do: "bg-info/10 text-info border-info/20"

  defp icono_tipo("fijo"), do: "hero-lock-closed-solid"
  defp icono_tipo(_), do: "hero-arrow-trending-up-solid"

  # ==========================================
  # RENDER
  # ==========================================

  @impl true
  def render(assigns) do
    ~H"""
    <AzarAppWeb.AdminSidebar.sidebar current_page="dashboard">
      <div class="w-full animate-in fade-in duration-700 relative z-10 pb-16">

        <%!-- ============================== --%>
        <%!-- HEADER --%>
        <%!-- ============================== --%>
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8">
          <div>
            <div class="inline-flex items-center gap-2 bg-primary/10 px-4 py-2 rounded-full border border-primary/20 w-fit mb-2">
              <.icon name="hero-chart-bar-square-solid" class="size-4 text-primary" />
              <span class="text-[10px] font-black uppercase tracking-[0.3em] text-primary">Centro de Control</span>
            </div>
            <h1 class="text-4xl md:text-5xl font-black italic uppercase tracking-tighter text-base-content">
              Dashboard <span class="text-primary">Analytics</span>
            </h1>
            <p class="text-xs font-bold opacity-40 uppercase tracking-[0.2em] mt-1">
              Visión completa del sistema en tiempo real
            </p>
          </div>
          <button
            phx-click="cambiar_tab"
            phx-value-tab="general"
            class="btn btn-ghost bg-base-200/60 hover:bg-base-200 rounded-2xl font-black text-[10px] uppercase tracking-widest gap-2 border border-base-300/40">
            <.icon name="hero-arrow-path-solid" class="size-4" />
            Actualizar
          </button>
        </div>

        <%!-- ============================== --%>
        <%!-- TABS DE NAVEGACIÓN --%>
        <%!-- ============================== --%>
        <div class="flex gap-2 mb-8 overflow-x-auto pb-1 scrollbar-none">
          <%= for {tab, label, icon} <- [
            {"general", "General", "hero-squares-2x2-solid"},
            {"usuarios", "Usuarios", "hero-users-solid"},
            {"financiero", "Finanzas", "hero-banknotes-solid"},
            {"sorteos", "Sorteos", "hero-ticket-solid"},
            {"calendario", "Calendario", "hero-calendar-solid"}
          ] do %>
            <button
              phx-click="cambiar_tab"
              phx-value-tab={tab}
              class={[
                "flex items-center gap-2 px-5 py-3 rounded-2xl font-black text-[10px] uppercase tracking-widest transition-all whitespace-nowrap border",
                @tab_activa == tab && "bg-primary text-white border-primary shadow-lg shadow-primary/30",
                @tab_activa != tab && "bg-base-100/60 text-base-content/50 border-base-200/60 hover:bg-base-200/80 hover:text-base-content"
              ]}>
              <.icon name={icon} class="size-4" />
              <%= label %>
            </button>
          <% end %>
        </div>

        <%!-- ============================== --%>
        <%!-- TAB: GENERAL --%>
        <%!-- ============================== --%>
        <%= if @tab_activa == "general" do %>

          <%!-- KPIs PRINCIPALES --%>
          <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <%= for {label, valor, icon, color} <- [
              {"Total Usuarios", fmt(@datos.usuarios.total), "hero-users-solid", "text-primary"},
              {"Sorteos Activos", fmt(@datos.sorteos.activos), "hero-ticket-solid", "text-success"},
              {"Tickets Vendidos", fmt(@datos.tickets.vendidos), "hero-shopping-cart-solid", "text-info"},
              {"Ganancia Casa", "$#{fmt(@datos.financiero.ganancia_casa)}", "hero-banknotes-solid", "text-warning"}
            ] do %>
              <div class="bg-base-100/80 backdrop-blur-xl p-6 rounded-[2rem] border border-base-200/60 shadow-lg hover:shadow-xl transition-all group">
                <div class="flex items-start justify-between mb-3">
                  <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40"><%= label %></p>
                  <div class={["p-2 rounded-xl bg-base-200/60 group-hover:scale-110 transition-transform", color]}>
                    <.icon name={icon} class="size-4" />
                  </div>
                </div>
                <p class={["text-3xl md:text-4xl font-black italic tracking-tighter", color]}><%= valor %></p>
              </div>
            <% end %>
          </div>

          <%!-- SEGUNDA FILA KPIs --%>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
            <div class="bg-base-100/80 p-5 rounded-[1.5rem] border border-base-200/60 shadow">
              <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-1">Con Compras</p>
              <p class="text-2xl font-black text-secondary"><%= fmt(@datos.usuarios.con_compras) %></p>
              <p class="text-[10px] text-base-content/30 mt-1">de <%= fmt(@datos.usuarios.total) %> usuarios</p>
            </div>
            <div class="bg-base-100/80 p-5 rounded-[1.5rem] border border-base-200/60 shadow">
              <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-1">Sin Compras</p>
              <p class="text-2xl font-black text-error"><%= fmt(@datos.usuarios.sin_compras) %></p>
              <p class="text-[10px] text-base-content/30 mt-1">usuarios inactivos</p>
            </div>
            <div class="bg-base-100/80 p-5 rounded-[1.5rem] border border-base-200/60 shadow">
              <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-1">Tasa de Venta</p>
              <p class="text-2xl font-black text-primary"><%= fmt(@datos.tickets.tasa_venta) %>%</p>
              <p class="text-[10px] text-base-content/30 mt-1">tickets vendidos</p>
            </div>
            <div class="bg-base-100/80 p-5 rounded-[1.5rem] border border-base-200/60 shadow">
              <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-1">Tasa de Éxito</p>
              <p class="text-2xl font-black text-success"><%= fmt(@datos.sorteos.tasa_exito) %>%</p>
              <p class="text-[10px] text-base-content/30 mt-1">sorteos completados</p>
            </div>
          </div>

          <%!-- GRÁFICA RECAUDO POR MES --%>
          <div class="bg-base-100/80 backdrop-blur-xl p-8 rounded-[2rem] border border-base-200/60 shadow-xl mb-8">
            <h3 class="font-black text-xl italic uppercase tracking-tight mb-6 flex items-center gap-3">
              <div class="p-2 bg-primary/10 rounded-xl"><.icon name="hero-chart-bar-solid" class="size-5 text-primary" /></div>
              Recaudo por Mes (Año Actual)
            </h3>

                <% max_recaudo =
                          Enum.reduce(@datos.recaudo_por_mes, Decimal.new("0"), fn mapa, acc ->
                  Decimal.add(acc, mapa.recaudo)
                end)
          %>

                  <div class="flex items-end gap-2 h-48">
        <%= for mes <- 1..12 do %>
          <%!-- 1. Corregido: Buscamos dentro de un mapa con la clave :mes --%>
          <% mes_data = Enum.find(@datos.recaudo_por_mes, fn m -> m.mes == mes end) %>

          <%!-- 2. Corregido: Extraemos el valor usando m.recaudo en lugar de elem/2 --%>
          <% valor = if mes_data, do: mes_data.recaudo, else: Decimal.new(0) %>

          <% pct_altura = if Decimal.compare(max_recaudo, Decimal.new(0)) == :gt, do: Decimal.mult(Decimal.div(valor, max_recaudo), Decimal.new(100)) |> Decimal.to_float() |> Float.round(1), else: 0.0 %>
          <div class="flex-1 flex flex-col items-center gap-1">
            <div class="w-full flex flex-col justify-end" style="height: 160px">
              <div
                class="w-full bg-primary/80 hover:bg-primary rounded-t-lg transition-all duration-700 cursor-pointer group relative"
                style={"height: #{max(pct_altura, 2)}%"}
                title={"$#{fmt(valor)}"}
              >
                      <%= if pct_altura > 15 do %>
                        <span class="absolute -top-5 left-1/2 -translate-x-1/2 text-[8px] font-black text-primary whitespace-nowrap hidden group-hover:block">
                          $<%= fmt(valor) %>
                        </span>
                      <% end %>
                    </div>
                  </div>
                  <span class="text-[8px] font-black uppercase text-base-content/40"><%= mes_nombre(mes) %></span>
                </div>
              <% end %>
            </div>
          </div>

          <%!-- FILA: ESTADO SORTEOS + ACTIVIDAD RECIENTE --%>
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">

            <%!-- Distribución Sorteos --%>
            <div class="bg-base-100/80 backdrop-blur-xl p-8 rounded-[2rem] border border-base-200/60 shadow-xl">
              <h3 class="font-black text-lg italic uppercase tracking-tight mb-6 flex items-center gap-3">
                <div class="p-2 bg-success/10 rounded-xl"><.icon name="hero-ticket-solid" class="size-5 text-success" /></div>
                Estado de Sorteos
              </h3>
              <div class="space-y-4">
                <%= for {label, val, color_bar, color_text} <- [
                  {"Activos", @datos.sorteos.activos, "bg-success", "text-success"},
                  {"Finalizados", @datos.sorteos.finalizados, "bg-primary", "text-primary"},
                  {"Cancelados", @datos.sorteos.cancelados, "bg-error", "text-error"}
                ] do %>
                  <% pct_val = pct(val, max(@datos.sorteos.total, 1)) %>
                  <div>
                    <div class="flex justify-between items-center mb-1.5">
                      <span class="text-[10px] font-black uppercase tracking-widest text-base-content/60"><%= label %></span>
                      <div class="flex items-center gap-2">
                        <span class={["text-sm font-black italic", color_text]}><%= fmt(val) %></span>
                        <span class="text-[9px] text-base-content/30">(<%= pct_val %>%)</span>
                      </div>
                    </div>
                    <div class="w-full h-2.5 bg-base-200 rounded-full overflow-hidden">
                      <div class={[color_bar, "h-full rounded-full transition-all duration-700"]} style={"width: #{pct_val}%"}></div>
                    </div>
                  </div>
                <% end %>

                <div class="mt-4 pt-4 border-t border-base-200/60 grid grid-cols-2 gap-3">
                  <div class="bg-base-200/40 p-3 rounded-xl text-center">
                    <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40">Fijos</p>
                    <p class="text-xl font-black text-warning"><%= fmt(@datos.sorteos.fijos) %></p>
                  </div>
                  <div class="bg-base-200/40 p-3 rounded-xl text-center">
                    <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40">Acumulados</p>
                    <p class="text-xl font-black text-info"><%= fmt(@datos.sorteos.acumulados) %></p>
                  </div>
                </div>
              </div>
            </div>

            <%!-- Actividad Reciente --%>
            <div class="bg-base-100/80 backdrop-blur-xl p-8 rounded-[2rem] border border-base-200/60 shadow-xl">
              <h3 class="font-black text-lg italic uppercase tracking-tight mb-6 flex items-center gap-3">
                <div class="p-2 bg-secondary/10 rounded-xl"><.icon name="hero-bolt-solid" class="size-5 text-secondary" /></div>
                Actividad Reciente
              </h3>
              <div class="space-y-2 max-h-64 overflow-y-auto scrollbar-thin scrollbar-thumb-base-300 pr-2">
                <%= if Enum.empty?(@datos.actividad_reciente) do %>
                  <p class="text-center text-base-content/30 font-bold text-sm py-8">Sin actividad registrada</p>
                <% else %>
                  <%= for actividad <- @datos.actividad_reciente do %>
                    <div class="flex items-center gap-3 p-3 rounded-xl hover:bg-base-200/40 transition-colors">
                      <div class="size-8 rounded-xl bg-secondary/10 flex items-center justify-center text-secondary font-black text-xs shrink-0">
                        #<%= actividad.numero_ticket %>
                      </div>
                      <div class="flex-1 min-w-0">
                        <p class="text-xs font-black text-base-content truncate"><%= actividad.usuario_nombre %></p>
                        <p class="text-[10px] text-base-content/40 truncate"><%= actividad.sorteo_titulo %></p>
                      </div>
                      <span class="text-xs font-black text-success shrink-0">$<%= fmt(actividad.precio) %></span>
                    </div>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>

        <% end %>

        <%!-- ============================== --%>
        <%!-- TAB: USUARIOS --%>
        <%!-- ============================== --%>
        <%= if @tab_activa == "usuarios" do %>

          <%!-- KPIs usuarios --%>
          <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4 mb-8">
            <%= for {label, valor, color} <- [
              {"Total", @datos.usuarios.total, "text-primary"},
              {"Activos", @datos.usuarios.activos, "text-success"},
              {"Inactivos", @datos.usuarios.inactivos, "text-error"},
              {"Con Compras", @datos.usuarios.con_compras, "text-secondary"},
              {"Nuevos este Mes", @datos.usuarios.nuevos_mes, "text-info"}
            ] do %>
              <div class="bg-base-100/80 p-5 rounded-[1.5rem] border border-base-200/60 shadow text-center">
                <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-2"><%= label %></p>
                <p class={["text-3xl font-black italic", color]}><%= fmt(valor) %></p>
              </div>
            <% end %>
          </div>

          <%!-- Barras usuarios vs compras --%>
          <div class="bg-base-100/80 p-8 rounded-[2rem] border border-base-200/60 shadow-xl mb-8">
            <h3 class="font-black text-lg italic uppercase tracking-tight mb-6 flex items-center gap-3">
              <div class="p-2 bg-secondary/10 rounded-xl"><.icon name="hero-users-solid" class="size-5 text-secondary" /></div>
              Distribución de Usuarios
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <%!-- Activos vs Inactivos --%>
              <div>
                <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 mb-3">Activos vs Inactivos</p>
                <div class="h-6 w-full bg-base-200 rounded-full overflow-hidden flex">
                  <div class="bg-success h-full transition-all duration-700"
                    style={"width: #{pct(@datos.usuarios.activos, max(@datos.usuarios.total, 1))}%"}>
                  </div>
                  <div class="bg-error h-full flex-1"></div>
                </div>
                <div class="flex justify-between mt-2 text-[10px] font-black">
                  <span class="text-success">Activos: <%= fmt(@datos.usuarios.activos) %></span>
                  <span class="text-error">Inactivos: <%= fmt(@datos.usuarios.inactivos) %></span>
                </div>
              </div>
              <%!-- Con compras vs sin compras --%>
              <div>
                <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 mb-3">Con Compras vs Sin Compras</p>
                <div class="h-6 w-full bg-base-200 rounded-full overflow-hidden flex">
                  <div class="bg-secondary h-full transition-all duration-700"
                    style={"width: #{pct(@datos.usuarios.con_compras, max(@datos.usuarios.total, 1))}%"}>
                  </div>
                  <div class="bg-base-300 h-full flex-1"></div>
                </div>
                <div class="flex justify-between mt-2 text-[10px] font-black">
                  <span class="text-secondary">Con compras: <%= fmt(@datos.usuarios.con_compras) %></span>
                  <span class="text-base-content/40">Sin compras: <%= fmt(@datos.usuarios.sin_compras) %></span>
                </div>
              </div>
            </div>

            <%!-- Nuevos por mes --%>
            <%= if not Enum.empty?(@datos.usuarios.nuevos_por_mes) do %>
              <div class="mt-6 pt-6 border-t border-base-200/60">
                <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 mb-4">Nuevos Usuarios por Mes</p>
                <% max_nuevos = Enum.max_by(@datos.usuarios.nuevos_por_mes, fn {_, v} -> v end, fn -> {1, 1} end) |> elem(1) %>
                <div class="flex items-end gap-2 h-24">
                  <%= for mes <- 1..12 do %>
                    <% mes_data = Enum.find(@datos.usuarios.nuevos_por_mes, fn {m, _} -> m == mes end) %>
                    <% val = if mes_data, do: elem(mes_data, 1), else: 0 %>
                    <% h = if max_nuevos > 0, do: Float.round(val / max_nuevos * 100, 0), else: 0 %>
                    <div class="flex-1 flex flex-col items-center gap-1">
                      <div class="w-full flex flex-col justify-end" style="height: 80px">
                        <div class="w-full bg-info/70 hover:bg-info rounded-t transition-all" style={"height: #{max(h, 2)}%"}></div>
                      </div>
                      <span class="text-[8px] font-black text-base-content/30"><%= mes_nombre(mes) %></span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <%!-- TOP COMPRADORES y TOP GANADORES --%>
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div class="bg-base-100/80 p-8 rounded-[2rem] border border-base-200/60 shadow-xl">
              <h3 class="font-black text-lg italic uppercase tracking-tight mb-5 flex items-center gap-3">
                <div class="p-2 bg-error/10 rounded-xl"><.icon name="hero-shopping-cart-solid" class="size-5 text-error" /></div>
                Top Compradores
              </h3>
              <div class="space-y-3">
                <%= for {usuario, idx} <- Enum.with_index(@datos.top_compradores, 1) do %>
                  <div class="flex items-center gap-3 p-3 rounded-xl hover:bg-base-200/40 transition-colors">
                    <span class={["size-7 flex items-center justify-center rounded-lg font-black text-xs", if(idx <= 3, do: "bg-warning/20 text-warning", else: "bg-base-200 text-base-content/40")]}>#<%= idx %></span>
                    <div class="size-8 rounded-xl bg-primary/10 flex items-center justify-center font-black text-sm text-primary shrink-0">
                      <%= String.first(usuario.nombre) %>
                    </div>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-black text-base-content truncate"><%= usuario.nombre %></p>
                      <p class="text-[9px] text-base-content/40 truncate"><%= usuario.email %></p>
                    </div>
                    <span class="text-sm font-black text-error shrink-0">$<%= fmt(usuario.total_gastado) %></span>
                  </div>
                <% end %>
                <%= if Enum.empty?(@datos.top_compradores) do %>
                  <p class="text-center text-base-content/30 font-bold text-sm py-6">Sin datos aún</p>
                <% end %>
              </div>
            </div>

            <div class="bg-base-100/80 p-8 rounded-[2rem] border border-base-200/60 shadow-xl">
              <h3 class="font-black text-lg italic uppercase tracking-tight mb-5 flex items-center gap-3">
                <div class="p-2 bg-warning/10 rounded-xl"><.icon name="hero-trophy-solid" class="size-5 text-warning" /></div>
                Top Ganadores
              </h3>
              <div class="space-y-3">
                <%= for {usuario, idx} <- Enum.with_index(@datos.top_ganadores, 1) do %>
                  <div class="flex items-center gap-3 p-3 rounded-xl hover:bg-base-200/40 transition-colors">
                    <span class={["size-7 flex items-center justify-center rounded-lg font-black text-xs", if(idx <= 3, do: "bg-warning/20 text-warning", else: "bg-base-200 text-base-content/40")]}>#<%= idx %></span>
                    <div class="size-8 rounded-xl bg-warning/10 flex items-center justify-center font-black text-sm text-warning shrink-0">
                      <%= String.first(usuario.nombre) %>
                    </div>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-black text-base-content truncate"><%= usuario.nombre %></p>
                      <p class="text-[9px] text-base-content/40 truncate"><%= usuario.email %></p>
                    </div>
                    <span class="text-sm font-black text-warning shrink-0">$<%= fmt(usuario.total_ganado) %></span>
                  </div>
                <% end %>
                <%= if Enum.empty?(@datos.top_ganadores) do %>
                  <p class="text-center text-base-content/30 font-bold text-sm py-6">Sin datos aún</p>
                <% end %>
              </div>
            </div>
          </div>

        <% end %>

        <%!-- ============================== --%>
        <%!-- TAB: FINANCIERO --%>
        <%!-- ============================== --%>
        <%= if @tab_activa == "financiero" do %>

          <%!-- KPIs financieros grandes --%>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
            <div class="bg-gradient-to-br from-success/10 to-success/5 p-8 rounded-[2rem] border border-success/20 shadow-xl">
              <div class="flex items-center gap-3 mb-3">
                <div class="p-3 bg-success/20 rounded-2xl"><.icon name="hero-arrow-trending-up-solid" class="size-7 text-success" /></div>
                <div>
                  <p class="text-[10px] font-black uppercase tracking-widest text-success/70">Total Invertido por Usuarios</p>
                  <p class="text-[10px] text-base-content/30">(Tickets comprados históricamente)</p>
                </div>
              </div>
              <p class="text-5xl font-black italic text-success">$<%= fmt(@datos.financiero.total_gastado_usuarios) %></p>
            </div>

            <div class={[
              "p-8 rounded-[2rem] border shadow-xl",
              if(Decimal.compare(@datos.financiero.ganancia_casa, Decimal.new(0)) in [:gt, :eq],
                do: "bg-gradient-to-br from-primary/10 to-primary/5 border-primary/20",
                else: "bg-gradient-to-br from-error/10 to-error/5 border-error/20")
            ]}>
              <div class="flex items-center gap-3 mb-3">
                <div class={["p-3 rounded-2xl", if(Decimal.compare(@datos.financiero.ganancia_casa, Decimal.new(0)) in [:gt, :eq], do: "bg-primary/20", else: "bg-error/20")]}>
                  <.icon name="hero-banknotes-solid" class={["size-7", if(Decimal.compare(@datos.financiero.ganancia_casa, Decimal.new(0)) in [:gt, :eq], do: "text-primary", else: "text-error")]} />
                </div>
                <div>
                  <p class={["text-[10px] font-black uppercase tracking-widest", if(Decimal.compare(@datos.financiero.ganancia_casa, Decimal.new(0)) in [:gt, :eq], do: "text-primary/70", else: "text-error/70")]}>
                    Ganancia / Pérdida de la Casa
                  </p>
                  <p class="text-[10px] text-base-content/30">(Recaudo menos premios pagados)</p>
                </div>
              </div>
              <p class={["text-5xl font-black italic", if(Decimal.compare(@datos.financiero.ganancia_casa, Decimal.new(0)) in [:gt, :eq], do: "text-primary", else: "text-error")]}>
                $<%= fmt(@datos.financiero.ganancia_casa) %>
              </p>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
            <div class="bg-base-100/80 p-6 rounded-[1.5rem] border border-base-200/60 shadow">
              <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-2 flex items-center gap-1">
                <.icon name="hero-trophy-solid" class="size-3 text-warning" /> Total Pagado en Premios
              </p>
              <p class="text-3xl font-black italic text-warning">$<%= fmt(@datos.financiero.total_ganado_usuarios) %></p>
            </div>
            <div class="bg-base-100/80 p-6 rounded-[1.5rem] border border-base-200/60 shadow">
              <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-2 flex items-center gap-1">
                <.icon name="hero-wallet-solid" class="size-3 text-info" /> Saldo en Circulación
              </p>
              <p class="text-3xl font-black italic text-info">$<%= fmt(@datos.financiero.saldo_en_circulacion) %></p>
            </div>
            <div class="bg-base-100/80 p-6 rounded-[1.5rem] border border-base-200/60 shadow">
              <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-2 flex items-center gap-1">
                <.icon name="hero-ticket-solid" class="size-3 text-secondary" /> Recaudo en Sorteos
              </p>
              <p class="text-3xl font-black italic text-secondary">$<%= fmt(@datos.financiero.recaudo_sorteos) %></p>
            </div>
          </div>
<%!-- Gráfica recaudo mensual aquí también --%>
<div class="bg-base-100/80 p-8 rounded-[2rem] border border-base-200/60 shadow-xl mb-8">
  <h3 class="font-black text-lg italic uppercase tracking-tight mb-6 flex items-center gap-3">
    <div class="p-2 bg-primary/10 rounded-xl">
      <.icon name="hero-chart-bar-solid" class="size-5 text-primary" />
    </div>
    Recaudo Mensual — Año en Curso
  </h3>

  <% max_r =
    Enum.reduce(@datos.recaudo_por_mes, Decimal.new("0"), fn mapa, acc ->
      Decimal.max(acc, mapa.recaudo)
    end) %>

  <% meses = ~w(Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic) %>

  <div class="flex items-end gap-2 h-48">
    <%= for mes <- 1..12 do %>
      <% md = Enum.find(@datos.recaudo_por_mes, fn m -> m.mes == mes end) %>

      <% v =
        if md,
          do: md.recaudo,
          else: Decimal.new("0") %>

      <% h =
        if Decimal.compare(max_r, Decimal.new("0")) == :gt,
          do:
            Decimal.mult(
              Decimal.div(v, max_r),
              Decimal.new(100)
            )
            |> Decimal.to_float()
            |> Float.round(1),
          else: 0.0 %>

      <div class="flex-1 flex flex-col items-center gap-1">
        <div class="w-full flex flex-col justify-end" style="height: 160px">
          <div
            class="w-full bg-primary/80 hover:bg-primary rounded-t-lg transition-all duration-700 cursor-pointer group relative"
            style={"height: #{max(h, 2.0)}%"}
            title={"$#{fmt(v)}"}
          >
          </div>
        </div>

        <span class="text-[10px] font-bold text-base-content/40 uppercase">
          <%= Enum.at(meses, mes - 1) %>
        </span>
      </div>
    <% end %>
  </div>
</div>
          <%!-- Top sorteos por tickets vendidos --%>
          <div class="bg-base-100/80 p-8 rounded-[2rem] border border-base-200/60 shadow-xl">
            <h3 class="font-black text-lg italic uppercase tracking-tight mb-5 flex items-center gap-3">
              <div class="p-2 bg-warning/10 rounded-xl"><.icon name="hero-fire-solid" class="size-5 text-warning" /></div>
              Sorteos con Más Ventas
            </h3>
            <% max_tickets = Enum.max_by(@datos.tickets.top_sorteos_tickets, fn x -> x.vendidos end, fn -> %{vendidos: 1} end).vendidos %>
            <div class="space-y-3">
              <%= for {sorteo, idx} <- Enum.with_index(@datos.tickets.top_sorteos_tickets, 1) do %>
                <div class="flex items-center gap-4">
                  <span class="text-[10px] font-black text-base-content/30 w-4">#<%= idx %></span>
                  <div class="flex-1">
                    <div class="flex justify-between mb-1">
                      <span class="text-xs font-black text-base-content truncate max-w-[60%]"><%= sorteo.titulo %></span>
                      <span class="text-xs font-black text-primary"><%= fmt(sorteo.vendidos) %> tickets</span>
                    </div>
                    <div class="w-full h-2 bg-base-200 rounded-full overflow-hidden">
                      <div class="h-full bg-primary/60 hover:bg-primary rounded-full transition-all"
                        style={"width: #{pct(sorteo.vendidos, max(max_tickets, 1))}%"}></div>
                    </div>
                  </div>
                </div>
              <% end %>
              <%= if Enum.empty?(@datos.tickets.top_sorteos_tickets) do %>
                <p class="text-center text-base-content/30 font-bold text-sm py-6">Sin ventas registradas</p>
              <% end %>
            </div>
          </div>

        <% end %>

        <%!-- ============================== --%>
        <%!-- TAB: SORTEOS --%>
        <%!-- ============================== --%>
        <%= if @tab_activa == "sorteos" do %>

          <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
            <%= for {label, val, color} <- [
              {"Total Sorteos", @datos.sorteos.total, "text-base-content"},
              {"Activos", @datos.sorteos.activos, "text-success"},
              {"Finalizados", @datos.sorteos.finalizados, "text-primary"},
              {"Cancelados", @datos.sorteos.cancelados, "text-error"}
            ] do %>
              <div class="bg-base-100/80 p-6 rounded-[1.5rem] border border-base-200/60 shadow text-center">
                <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-2"><%= label %></p>
                <p class={["text-3xl font-black italic", color]}><%= fmt(val) %></p>
              </div>
            <% end %>
          </div>

          <%!-- Tickets stats --%>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
            <div class="bg-base-100/80 p-6 rounded-[1.5rem] border border-base-200/60 shadow">
              <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-2">Total Tickets</p>
              <p class="text-3xl font-black italic text-base-content"><%= fmt(@datos.tickets.total) %></p>
            </div>
            <div class="bg-base-100/80 p-6 rounded-[1.5rem] border border-base-200/60 shadow">
              <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-2">Vendidos</p>
              <p class="text-3xl font-black italic text-success"><%= fmt(@datos.tickets.vendidos) %></p>
            </div>
            <div class="bg-base-100/80 p-6 rounded-[1.5rem] border border-base-200/60 shadow">
              <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-2">Disponibles</p>
              <p class="text-3xl font-black italic text-info"><%= fmt(@datos.tickets.disponibles) %></p>
            </div>
          </div>

          <%!-- Tasa de venta visual --%>
          <div class="bg-base-100/80 p-8 rounded-[2rem] border border-base-200/60 shadow-xl mb-8">
            <div class="flex justify-between items-center mb-4">
              <h3 class="font-black text-lg italic uppercase tracking-tight flex items-center gap-3">
                <div class="p-2 bg-info/10 rounded-xl"><.icon name="hero-chart-pie-solid" class="size-5 text-info" /></div>
                Tasa de Venta Global
              </h3>
              <span class="text-4xl font-black italic text-info"><%= fmt(@datos.tickets.tasa_venta) %>%</span>
            </div>
            <div class="w-full h-5 bg-base-200 rounded-full overflow-hidden">
              <div class="h-full bg-gradient-to-r from-info/60 to-info rounded-full transition-all duration-1000"
                style={"width: #{@datos.tickets.tasa_venta}%"}></div>
            </div>
            <div class="flex justify-between mt-2 text-[10px] font-black text-base-content/40">
              <span><%= fmt(@datos.tickets.vendidos) %> vendidos</span>
              <span><%= fmt(@datos.tickets.disponibles) %> disponibles</span>
            </div>
          </div>

          <%!-- Tipos de sorteo --%>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
            <div class="bg-base-100/80 p-8 rounded-[2rem] border border-base-200/60 shadow-xl">
              <h3 class="font-black text-lg italic uppercase tracking-tight mb-5">Tipo de Premio</h3>
              <div class="space-y-4">
                <div>
                  <div class="flex justify-between mb-1.5">
                    <span class="text-xs font-black text-warning flex items-center gap-1">
                      <.icon name="hero-lock-closed-solid" class="size-3" /> Fijos
                    </span>
                    <span class="text-xs font-black"><%= fmt(@datos.sorteos.fijos) %></span>
                  </div>
                  <div class="h-3 bg-base-200 rounded-full overflow-hidden">
                    <div class="h-full bg-warning rounded-full" style={"width: #{pct(@datos.sorteos.fijos, max(@datos.sorteos.total, 1))}%"}></div>
                  </div>
                </div>
                <div>
                  <div class="flex justify-between mb-1.5">
                    <span class="text-xs font-black text-info flex items-center gap-1">
                      <.icon name="hero-arrow-trending-up-solid" class="size-3" /> Acumulados
                    </span>
                    <span class="text-xs font-black"><%= fmt(@datos.sorteos.acumulados) %></span>
                  </div>
                  <div class="h-3 bg-base-200 rounded-full overflow-hidden">
                    <div class="h-full bg-info rounded-full" style={"width: #{pct(@datos.sorteos.acumulados, max(@datos.sorteos.total, 1))}%"}></div>
                  </div>
                </div>
              </div>
            </div>

            <div class="bg-base-100/80 p-8 rounded-[2rem] border border-base-200/60 shadow-xl">
              <h3 class="font-black text-lg italic uppercase tracking-tight mb-5">Tasa de Éxito</h3>
              <div class="flex items-center justify-center h-24">
                <div class="text-center">
                  <p class="text-6xl font-black italic text-success"><%= fmt(@datos.sorteos.tasa_exito) %>%</p>
                  <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 mt-2">sorteos finalizados correctamente</p>
                </div>
              </div>
            </div>
          </div>

        <% end %>

        <%!-- ============================== --%>
        <%!-- TAB: CALENDARIO --%>
        <%!-- ============================== --%>
        <%= if @tab_activa == "calendario" do %>

          <div class="grid grid-cols-1 lg:grid-cols-5 gap-6">

            <%!-- Lista de sorteos próximos --%>
            <div class="lg:col-span-2 space-y-4">
              <div class="bg-base-100/80 p-6 rounded-[2rem] border border-base-200/60 shadow-xl">
                <h3 class="font-black text-lg italic uppercase tracking-tight mb-4 flex items-center gap-3">
                  <div class="p-2 bg-primary/10 rounded-xl"><.icon name="hero-calendar-days-solid" class="size-5 text-primary" /></div>
                  Próximos Sorteos
                </h3>

                <%= if Enum.empty?(@datos.proximos_sorteos) do %>
                  <div class="text-center py-8">
                    <.icon name="hero-calendar-solid" class="size-12 text-base-content/20 mb-3 mx-auto" />
                    <p class="font-black text-sm text-base-content/40 uppercase tracking-widest">Sin sorteos programados</p>
                  </div>
                <% else %>
                  <div class="space-y-3 max-h-[600px] overflow-y-auto pr-1 scrollbar-thin scrollbar-thumb-base-300">
                    <%= for sorteo <- @datos.proximos_sorteos do %>
                      <div class="p-4 rounded-2xl bg-base-200/40 border border-base-300/30 hover:border-primary/30 hover:bg-base-200/60 transition-all group">
                        <div class="flex items-start justify-between gap-2 mb-2">
                          <p class="font-black text-sm text-base-content italic leading-tight"><%= sorteo.titulo %></p>
                          <span class={["px-2 py-1 rounded-lg text-[9px] font-black uppercase tracking-widest border shrink-0", color_tipo(sorteo.tipo_premio)]}>
                            <%= if sorteo.tipo_premio == "fijo", do: "Fijo", else: "Acum." %>
                          </span>
                        </div>
                        <div class="flex items-center justify-between">
                          <div class="flex items-center gap-1.5 text-[10px] text-base-content/50">
                            <.icon name="hero-calendar-solid" class="size-3" />
                            <%= Calendar.strftime(sorteo.fecha_ejecucion, "%d %b %Y · %H:%M") %>
                          </div>
                          <span class="text-[10px] font-black text-primary">$<%= fmt(sorteo.precio_ticket) %></span>
                        </div>
                        <%!-- Días restantes --%>
                        <% dias = NaiveDateTime.diff(sorteo.fecha_ejecucion, NaiveDateTime.utc_now(), :second) |> div(86400) %>
                        <div class="mt-2">
                          <div class={[
                            "inline-flex items-center gap-1 px-2 py-0.5 rounded-lg text-[9px] font-black uppercase tracking-wider",
                            cond do
                              dias <= 1 -> "bg-error/10 text-error"
                              dias <= 7 -> "bg-warning/10 text-warning"
                              true -> "bg-success/10 text-success"
                            end
                          ]}>
                            <.icon name="hero-clock-solid" class="size-2.5" />
                            <%= cond do
                              dias <= 0 -> "Hoy"
                              dias == 1 -> "Mañana"
                              true -> Integer.to_string(dias) <> " días"
                            end %>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <%!-- Sorteos sin fecha --%>
              <%= if not Enum.empty?(@datos.sorteos_sin_fecha) do %>
                <div class="bg-base-100/80 p-6 rounded-[2rem] border border-warning/20 shadow-xl bg-warning/5">
                  <h3 class="font-black text-sm italic uppercase tracking-tight mb-3 flex items-center gap-2 text-warning">
                    <.icon name="hero-exclamation-triangle-solid" class="size-4" />
                    Sin Fecha Asignada
                  </h3>
                  <div class="space-y-2">
                    <%= for sorteo <- @datos.sorteos_sin_fecha do %>
                      <div class="p-3 rounded-xl bg-warning/5 border border-warning/10 flex items-center justify-between">
                        <p class="text-xs font-black text-base-content truncate"><%= sorteo.titulo %></p>
                        <.link navigate={~p"/admin/sorteos/#{sorteo.id}"} class="btn btn-xs rounded-lg font-black text-[9px] uppercase tracking-widest bg-warning/10 text-warning border border-warning/20 hover:bg-warning hover:text-white">
                          Gestionar
                        </.link>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>

            <%!-- Calendario visual --%>
            <div class="lg:col-span-3">
              <div class="bg-base-100/80 p-8 rounded-[2rem] border border-base-200/60 shadow-xl">
                <% hoy = Date.utc_today() %>
                <% primer_dia = Date.beginning_of_month(hoy) %>
                <% dias_en_mes = Date.days_in_month(hoy) %>
                <% dia_semana_inicio = Date.day_of_week(primer_dia) |> rem(7) %>
                <%!-- Convertimos fechas de sorteos próximos a un Set de días --%>
                <% dias_con_sorteo = @datos.proximos_sorteos
                    |> Enum.filter(fn s ->
                      fecha = NaiveDateTime.to_date(s.fecha_ejecucion)
                      fecha.year == hoy.year and fecha.month == hoy.month
                    end)
                    |> Enum.map(fn s -> NaiveDateTime.to_date(s.fecha_ejecucion).day end)
                    |> MapSet.new() %>

                <div class="flex items-center justify-between mb-6">
                  <h3 class="font-black text-xl italic uppercase tracking-tight">
                    <%= Calendar.strftime(hoy, "%B %Y") %>
                  </h3>
                  <div class="flex items-center gap-3 text-[10px] font-black uppercase">
                    <span class="flex items-center gap-1">
                      <span class="size-3 rounded-full bg-primary inline-block"></span> Hoy
                    </span>
                    <span class="flex items-center gap-1">
                      <span class="size-3 rounded-full bg-success inline-block"></span> Sorteo
                    </span>
                  </div>
                </div>

                <%!-- Encabezados días --%>
                <div class="grid grid-cols-7 gap-1 mb-2">
                  <%= for dia <- ~w(Dom Lun Mar Mié Jue Vie Sáb) do %>
                    <div class="text-center text-[9px] font-black uppercase tracking-widest text-base-content/40 py-2"><%= dia %></div>
                  <% end %>
                </div>

                <%!-- Grid del calendario --%>
                <div class="grid grid-cols-7 gap-1">
                  <%!-- Espacios vacíos al inicio --%>
                  <%= for _ <- 1..dia_semana_inicio do %>
                    <div></div>
                  <% end %>

                  <%= for dia <- 1..dias_en_mes do %>
                    <div class={[
                      "aspect-square flex flex-col items-center justify-center rounded-xl text-sm font-black transition-all cursor-default relative",
                      cond do
                        dia == hoy.day -> "bg-primary text-white shadow-lg shadow-primary/30"
                        MapSet.member?(dias_con_sorteo, dia) -> "bg-success/15 text-success border border-success/30"
                        true -> "hover:bg-base-200/60 text-base-content/70"
                      end
                    ]}>
                      <%= dia %>
                      <%= if MapSet.member?(dias_con_sorteo, dia) and dia != hoy.day do %>
                        <span class="absolute bottom-1 left-1/2 -translate-x-1/2 size-1 bg-success rounded-full"></span>
                      <% end %>
                    </div>
                  <% end %>
                </div>

                <%!-- Leyenda de sorteos del mes --%>
                <% sorteos_este_mes = Enum.filter(@datos.proximos_sorteos, fn s ->
                  fecha = NaiveDateTime.to_date(s.fecha_ejecucion)
                  fecha.year == hoy.year and fecha.month == hoy.month
                end) %>

                <%= if not Enum.empty?(sorteos_este_mes) do %>
                  <div class="mt-6 pt-5 border-t border-base-200/60">
                    <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 mb-3">Sorteos este mes</p>
                    <div class="space-y-2">
                      <%= for s <- sorteos_este_mes do %>
                        <div class="flex items-center gap-3">
                          <span class="size-6 bg-success/20 text-success rounded-lg flex items-center justify-center text-[10px] font-black shrink-0">
                            <%= NaiveDateTime.to_date(s.fecha_ejecucion).day %>
                          </span>
                          <span class="text-xs font-bold text-base-content/70 flex-1 truncate"><%= s.titulo %></span>
                          <span class="text-[10px] font-black text-base-content/40">
                            <%= Calendar.strftime(s.fecha_ejecucion, "%H:%M") %>
                          </span>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

        <% end %>

      </div>
    </AzarAppWeb.AdminSidebar.sidebar>
    """
  end
end
