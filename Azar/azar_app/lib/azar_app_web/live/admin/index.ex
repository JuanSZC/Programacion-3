defmodule AzarAppWeb.Admin.SorteoLive.Index do
  use AzarAppWeb, :live_view
  alias AzarApp.Sorteos

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(AzarApp.PubSub, "sorteos")

    sorteos = Sorteos.list_sorteos()

    {:ok,
     socket
     |> assign(:sorteos_base, sorteos)
     |> assign(:filtros, filtros_default())
     |> assign(:show_filtros, false)
     |> assign(:esta_vacio, Enum.empty?(sorteos))
     |> stream(:sorteos, sorteos)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Crear Nuevo Sorteo")
    |> assign(:sorteo, %AzarApp.Sorteos.Sorteo{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Panel de Administración")
    |> assign(:sorteo, nil)
  end


  @impl true
  def handle_event("toggle_filtros", _, socket) do
    {:noreply, assign(socket, :show_filtros, !socket.assigns.show_filtros)}
  end

  @impl true
  def handle_event("filtrar", params, socket) do
    filtros = %{
      mes:       Map.get(params, "mes", ""),
      orden:     Map.get(params, "orden", "fecha_desc"),
      tipo:      Map.get(params, "tipo", "todos"),
      estado:    Map.get(params, "estado", "todos"),
      con_ventas: Map.get(params, "con_ventas", "todos")
    }

    sorteos = socket.assigns.sorteos_base |> aplicar_filtros(filtros)

    {:noreply,
     socket
     |> assign(:filtros, filtros)
     |> assign(:esta_vacio, Enum.empty?(sorteos))
     |> stream(:sorteos, sorteos, reset: true)}
  end

  @impl true
  def handle_event("limpiar_filtros", _, socket) do
    filtros = filtros_default()
    sorteos = socket.assigns.sorteos_base |> aplicar_filtros(filtros)

    {:noreply,
     socket
     |> assign(:filtros, filtros)
     |> assign(:esta_vacio, Enum.empty?(sorteos))
     |> stream(:sorteos, sorteos, reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    sorteo = Sorteos.get_sorteo!(id)
    {:ok, _} = Sorteos.delete_sorteo(sorteo)
    base = Sorteos.list_sorteos()
    sorteos = base |> aplicar_filtros(socket.assigns.filtros)

    {:noreply,
     socket
     |> assign(:sorteos_base, base)
     |> assign(:esta_vacio, Enum.empty?(sorteos))
     |> stream(:sorteos, sorteos, reset: true)}
  end


  @impl true
  def handle_info({:saved, sorteo}, socket) do
    base = [sorteo | socket.assigns.sorteos_base]
    sorteos = base |> aplicar_filtros(socket.assigns.filtros)
    {:noreply,
     socket
     |> assign(:sorteos_base, base)
     |> assign(:esta_vacio, false)
     |> stream(:sorteos, sorteos, reset: true)}
  end

  @impl true
  def handle_info({:sorteo_creado, _}, socket), do: reload(socket)
  def handle_info({:sorteo_eliminado, _}, socket), do: reload(socket)
  def handle_info(:lista_actualizada, socket), do: reload(socket)

  defp reload(socket) do
    base = Sorteos.list_sorteos()
    sorteos = base |> aplicar_filtros(socket.assigns.filtros)
    {:noreply,
     socket
     |> assign(:sorteos_base, base)
     |> assign(:esta_vacio, Enum.empty?(sorteos))
     |> stream(:sorteos, sorteos, reset: true)}
  end


  defp filtros_default do
    %{mes: "", orden: "fecha_desc", tipo: "todos", estado: "todos", con_ventas: "todos"}
  end

  defp filtros_activos?(filtros), do: filtros != filtros_default()

  defp aplicar_filtros(sorteos, filtros) do
    sorteos
    |> filtrar_mes(filtros.mes)
    |> filtrar_tipo(filtros.tipo)
    |> filtrar_estado(filtros.estado)
    |> filtrar_ventas(filtros.con_ventas)
    |> ordenar(filtros.orden)
  end

  defp filtrar_mes(sorteos, ""), do: sorteos
  defp filtrar_mes(sorteos, mes) do
    {m, _} = Integer.parse(mes)
    Enum.filter(sorteos, fn s ->
      s.fecha_ejecucion && s.fecha_ejecucion.month == m
    end)
  end

  defp filtrar_tipo(sorteos, "todos"), do: sorteos
  defp filtrar_tipo(sorteos, tipo), do: Enum.filter(sorteos, &(&1.tipo_premio == tipo))

  defp filtrar_estado(sorteos, "todos"), do: sorteos
  defp filtrar_estado(sorteos, estado), do: Enum.filter(sorteos, &(&1.estado == estado))

  defp filtrar_ventas(sorteos, "todos"), do: sorteos
  defp filtrar_ventas(sorteos, "con"), do: Enum.filter(sorteos, &((&1.total_vendidos || 0) > 0))
  defp filtrar_ventas(sorteos, "sin"), do: Enum.filter(sorteos, &((&1.total_vendidos || 0) == 0))

  defp ordenar(sorteos, "nombre_az"), do: Enum.sort_by(sorteos, &String.downcase(&1.titulo))
  defp ordenar(sorteos, "nombre_za"), do: Enum.sort_by(sorteos, &String.downcase(&1.titulo), :desc)
  defp ordenar(sorteos, "fecha_asc"), do: Enum.sort_by(sorteos, & &1.fecha_ejecucion, Date)
  defp ordenar(sorteos, "fecha_desc"), do: Enum.sort_by(sorteos, & &1.inserted_at, {:desc, NaiveDateTime})
  defp ordenar(sorteos, "tickets_asc"), do: Enum.sort_by(sorteos, & &1.total_tickets)
  defp ordenar(sorteos, "tickets_desc"), do: Enum.sort_by(sorteos, & &1.total_tickets, :desc)
  defp ordenar(sorteos, "precio_asc"), do: Enum.sort_by(sorteos, & &1.precio_ticket, Decimal)
  defp ordenar(sorteos, "precio_desc"), do: Enum.sort_by(sorteos, & &1.precio_ticket, {:desc, Decimal})
  defp ordenar(sorteos, _), do: sorteos

  @impl true
  def render(assigns) do
    ~H"""
    <AzarAppWeb.AdminSidebar.sidebar current_page="sorteos">
      <div class="w-full animate-in fade-in duration-700 relative z-10">

        <%!-- HEADER --%>
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-8">
          <div class="flex flex-col gap-2">
            <div class="inline-flex items-center gap-2 bg-primary/10 px-4 py-2 rounded-full border border-primary/20 w-fit">
              <.icon name="hero-command-line-solid" class="size-4 text-primary" />
              <span class="text-[10px] font-black uppercase tracking-[0.3em] text-primary">Administración</span>
            </div>
            <h1 class="text-4xl md:text-5xl font-black italic uppercase tracking-tighter text-base-content mt-1">
              Panel de <span class="text-primary drop-shadow-md">Sorteos</span>
            </h1>
          </div>
          <div class="flex gap-3 w-full sm:w-auto">
            <%!-- BOTÓN FILTROS --%>
            <button phx-click="toggle_filtros"
              class={[
                "btn h-14 px-6 rounded-2xl font-black text-xs uppercase tracking-widest gap-2 border transition-all relative",
                if(@show_filtros,
                  do: "btn-primary shadow-lg shadow-primary/20",
                  else: "bg-base-100/80 border-base-200/60 hover:border-primary/30 hover:bg-primary/5")
              ]}>
              <.icon name="hero-funnel-solid" class="size-5" />
              Filtros
              <%= if filtros_activos?(@filtros) do %>
                <span class="absolute -top-1.5 -right-1.5 size-4 bg-warning rounded-full border-2 border-base-100 animate-pulse"></span>
              <% end %>
            </button>
            <.link patch={~p"/admin/sorteos/new"} class="btn btn-primary h-14 px-8 rounded-2xl shadow-xl shadow-primary/30 gap-3 flex-1 sm:flex-none hover:-translate-y-1 transition-all font-black text-xs uppercase tracking-widest border border-primary/50 group">
              <div class="bg-white/20 p-1.5 rounded-lg group-hover:scale-110 transition-transform">
                <.icon name="hero-plus-solid" class="size-5" />
              </div>
              Nuevo Sorteo
            </.link>
          </div>
        </div>

        <%!-- PANEL DE FILTROS --%>
        <%= if @show_filtros do %>
          <div class="bg-base-100/90 backdrop-blur-xl border border-base-200/60 rounded-[2rem] p-6 mb-8 shadow-xl animate-in slide-in-from-top-4 duration-300">
            <form phx-change="filtrar" phx-submit="filtrar">
              <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">

                <%!-- MES --%>
                <div class="flex flex-col gap-1.5">
                  <label class="text-[9px] font-black uppercase tracking-widest text-base-content/40 ml-1">Mes</label>
                  <select name="mes" class="select select-bordered h-11 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-primary/30 font-bold text-sm">
                    <option value="">Todos</option>
                    <%= for {nombre, num} <- meses() do %>
                      <option value={num} selected={@filtros.mes == "#{num}"}><%= nombre %></option>
                    <% end %>
                  </select>
                </div>

                <%!-- TIPO --%>
                <div class="flex flex-col gap-1.5">
                  <label class="text-[9px] font-black uppercase tracking-widest text-base-content/40 ml-1">Tipo de Premio</label>
                  <select name="tipo" class="select select-bordered h-11 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-primary/30 font-bold text-sm">
                    <option value="todos" selected={@filtros.tipo == "todos"}>Todos</option>
                    <option value="fijo" selected={@filtros.tipo == "fijo"}>Premio Fijo</option>
                    <option value="acumulado" selected={@filtros.tipo == "acumulado"}>Acumulado</option>
                  </select>
                </div>

                <%!-- ESTADO --%>
                <div class="flex flex-col gap-1.5">
                  <label class="text-[9px] font-black uppercase tracking-widest text-base-content/40 ml-1">Estado</label>
                  <select name="estado" class="select select-bordered h-11 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-primary/30 font-bold text-sm">
                    <option value="todos" selected={@filtros.estado == "todos"}>Todos</option>
                    <option value="activo" selected={@filtros.estado == "activo"}>Activo</option>
                    <option value="finalizado" selected={@filtros.estado == "finalizado"}>Finalizado</option>
                  </select>
                </div>

                <%!-- VENTAS --%>
                <div class="flex flex-col gap-1.5">
                  <label class="text-[9px] font-black uppercase tracking-widest text-base-content/40 ml-1">Tickets</label>
                  <select name="con_ventas" class="select select-bordered h-11 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-primary/30 font-bold text-sm">
                    <option value="todos" selected={@filtros.con_ventas == "todos"}>Todos</option>
                    <option value="con" selected={@filtros.con_ventas == "con"}>Con ventas</option>
                    <option value="sin" selected={@filtros.con_ventas == "sin"}>Sin ventas</option>
                  </select>
                </div>

                <%!-- ORDEN --%>
                <div class="flex flex-col gap-1.5">
                  <label class="text-[9px] font-black uppercase tracking-widest text-base-content/40 ml-1">Ordenar por</label>
                  <select name="orden" class="select select-bordered h-11 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-primary/30 font-bold text-sm">
                    <option value="fecha_desc" selected={@filtros.orden == "fecha_desc"}>Más reciente</option>
                    <option value="fecha_asc" selected={@filtros.orden == "fecha_asc"}>Más antiguo</option>
                    <option value="nombre_az" selected={@filtros.orden == "nombre_az"}>Nombre A→Z</option>
                    <option value="nombre_za" selected={@filtros.orden == "nombre_za"}>Nombre Z→A</option>
                    <option value="tickets_desc" selected={@filtros.orden == "tickets_desc"}>Más tickets</option>
                    <option value="tickets_asc" selected={@filtros.orden == "tickets_asc"}>Menos tickets</option>
                    <option value="precio_desc" selected={@filtros.orden == "precio_desc"}>Mayor precio</option>
                    <option value="precio_asc" selected={@filtros.orden == "precio_asc"}>Menor precio</option>
                  </select>
                </div>
              </div>

              <%= if filtros_activos?(@filtros) do %>
                <div class="mt-4 pt-4 border-t border-base-200/60 flex justify-end">
                  <button type="button" phx-click="limpiar_filtros"
                    class="btn btn-ghost btn-sm rounded-xl font-black text-[9px] uppercase tracking-widest text-error hover:bg-error/10 gap-1.5">
                    <.icon name="hero-x-mark-solid" class="size-3.5" />
                    Limpiar filtros
                  </button>
                </div>
              <% end %>
            </form>
          </div>
        <% end %>

        <%!-- CONTENIDO --%>
        <%= if @esta_vacio do %>
          <div class="h-[40vh] bg-base-100/50 border-2 border-dashed border-base-300/50 rounded-[3rem] flex flex-col items-center justify-center text-base-content/40">
            <.icon name="hero-funnel-solid" class="size-12 mb-4 opacity-20" />
            <h2 class="text-xl font-black uppercase tracking-tight italic">Sin resultados</h2>
            <p class="text-[10px] font-bold mt-2 uppercase tracking-widest">Prueba ajustando los filtros</p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-8" id="sorteos" phx-update="stream">
            <div :for={{id, sorteo} <- @streams.sorteos} id={id}
              class="bg-base-100/80 backdrop-blur-xl shadow-xl hover:shadow-2xl border border-base-200/60 hover:border-primary/30 transition-all duration-500 rounded-[2.5rem] group relative overflow-hidden flex flex-col">
              <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-primary/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
              <div class="p-8 flex flex-col h-full">
                <div class="flex justify-between items-start gap-4 mb-4">
                  <h2 class="text-2xl font-black italic uppercase tracking-tight text-base-content leading-tight line-clamp-2 drop-shadow-sm">
                    <%= sorteo.titulo %>
                  </h2>
                  <div class={[
                    "px-3 py-1.5 rounded-xl font-black text-[9px] uppercase tracking-widest whitespace-nowrap border shadow-sm shrink-0",
                    if(sorteo.estado == "activo", do: "bg-success/10 text-success border-success/20", else: "bg-base-200 text-base-content/50 border-base-300")
                  ]}>
                    <%= sorteo.estado %>
                  </div>
                </div>
                <div class="flex flex-wrap gap-3 mt-2">
                  <span class={[
                    "inline-flex items-center gap-2 px-3 py-2 rounded-xl text-[10px] font-black uppercase tracking-wider border border-base-300/30",
                    if(sorteo.tipo_premio == "fijo", do: "bg-warning/10 text-warning border-warning/20", else: "bg-info/10 text-info border-info/20")
                  ]}>
                    <.icon name={if sorteo.tipo_premio == "fijo", do: "hero-lock-closed-solid", else: "hero-arrow-trending-up-solid"} class="size-4" />
                    <%= if sorteo.tipo_premio == "fijo", do: "Premio Fijo", else: "Acumulado" %>
                  </span>
                  <span class="inline-flex items-center gap-2 px-3 py-2 rounded-xl bg-base-200/50 text-[10px] font-black uppercase tracking-wider text-base-content/70 border border-base-300/30">
                    <.icon name="hero-ticket-solid" class="size-4 text-info" />
                    <%= sorteo.total_tickets %> Tickets
                  </span>
                </div>
                <div class="w-full h-px bg-gradient-to-r from-transparent via-base-300/50 to-transparent my-6"></div>
                <div class="flex items-center justify-between mb-4">
                  <div>
                    <p class="text-[9px] uppercase font-black text-base-content/40 tracking-[0.2em] mb-1">Precio Ticket</p>
                    <p class="text-3xl font-black text-primary italic tracking-tighter">$<%= sorteo.precio_ticket %></p>
                  </div>
                  <div class="text-right">
                    <p class="text-[9px] uppercase font-black text-base-content/40 tracking-[0.2em] mb-1">Ejecución</p>
                    <p class="text-sm font-bold text-base-content/80 uppercase tracking-wider">
                      <%= if sorteo.fecha_ejecucion, do: Calendar.strftime(sorteo.fecha_ejecucion, "%d %b, %Y"), else: "Por definir" %>
                    </p>
                  </div>
                </div>
                <%= if sorteo.estado == "finalizado" and not Enum.empty?(sorteo.numeros_ganadores || []) do %>
                  <div class="flex items-center gap-4 bg-warning/10 border border-warning/20 rounded-2xl px-5 py-4 mb-4">
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
                <div class="flex justify-between items-center mt-auto pt-2">
                  <button phx-click="delete" phx-value-id={sorteo.id} data-confirm="¿Eliminar este sorteo permanentemente?"
                    class="btn btn-circle btn-ghost text-base-content/30 hover:text-error hover:bg-error/10 transition-colors">
                    <.icon name="hero-trash-solid" class="size-5" />
                  </button>
                  <.link navigate={~p"/admin/sorteos/#{sorteo.id}"} class="btn btn-primary h-12 px-8 rounded-2xl shadow-lg shadow-primary/20 hover:-translate-y-1 transition-transform font-black text-[10px] uppercase tracking-widest gap-2">
                    Gestionar <.icon name="hero-arrow-right-circle-solid" class="size-4" />
                  </.link>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @live_action == :new do %>
        <div class="modal modal-open backdrop-blur-md bg-base-300/40 transition-all duration-500">
          <div class="modal-box relative rounded-[3rem] shadow-2xl p-0 overflow-hidden bg-base-100/95 border border-base-200/60 max-w-2xl animate-in zoom-in-95 duration-300">
            <div class="bg-base-200/50 px-8 py-6 flex justify-between items-center border-b border-base-200/50 backdrop-blur-xl">
              <div class="flex items-center gap-3">
                <div class="p-2 bg-primary/10 rounded-xl">
                  <.icon name="hero-sparkles-solid" class="size-5 text-primary" />
                </div>
                <h3 class="text-xl font-black italic uppercase tracking-tight text-base-content"><%= @page_title %></h3>
              </div>
              <.link patch={~p"/admin/sorteos"} class="btn btn-ghost btn-circle btn-sm hover:bg-error/10 hover:text-error transition-colors">
                <.icon name="hero-x-mark-solid" class="size-5" />
              </.link>
            </div>
            <div class="p-8">
              <.live_component
                module={AzarAppWeb.Admin.SorteoLive.FormComponent}
                id={:new}
                title={@page_title}
                action={@live_action}
                sorteo={@sorteo}
                patch={~p"/admin/sorteos"}
              />
            </div>
          </div>
          <.link patch={~p"/admin/sorteos"} class="modal-backdrop bg-transparent"><button>Cerrar</button></.link>
        </div>
      <% end %>
    </AzarAppWeb.AdminSidebar.sidebar>
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
