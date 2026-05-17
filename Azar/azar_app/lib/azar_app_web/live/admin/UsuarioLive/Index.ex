defmodule AzarAppWeb.Admin.UsuarioLive.Index do
  use AzarAppWeb, :live_view
  alias AzarApp.Cuentas

  @impl true
  def mount(_params, _session, socket) do
    usuarios = Cuentas.list_usuarios()
    {:ok,
     socket
     |> assign(:usuarios_base, usuarios)
     |> assign(:usuarios, usuarios)
     |> assign(:query, "")
     |> assign(:filtros, filtros_default())
     |> assign(:show_filtros, false)
     |> assign(:total, length(usuarios))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Gestión de Clientes")}
  end

  @impl true
  def handle_event("buscar", %{"q" => q}, socket) do
    base = if String.trim(q) == "",
      do: Cuentas.list_usuarios(),
      else: Cuentas.buscar_usuarios(q)

    usuarios = aplicar_filtros(base, socket.assigns.filtros)
    {:noreply, assign(socket, usuarios_base: base, usuarios: usuarios, query: q)}
  end

  @impl true
  def handle_event("toggle_filtros", _, socket) do
    {:noreply, assign(socket, :show_filtros, !socket.assigns.show_filtros)}
  end

  @impl true
  def handle_event("filtrar", params, socket) do
    filtros = %{
      estado: Map.get(params, "estado", "todos"),
      orden:  Map.get(params, "orden", "reciente")
    }
    usuarios = aplicar_filtros(socket.assigns.usuarios_base, filtros)
    {:noreply, assign(socket, filtros: filtros, usuarios: usuarios)}
  end

  @impl true
  def handle_event("limpiar_filtros", _, socket) do
    filtros = filtros_default()
    usuarios = aplicar_filtros(socket.assigns.usuarios_base, filtros)
    {:noreply, assign(socket, filtros: filtros, usuarios: usuarios)}
  end

  @impl true
  def handle_event("toggle_activo", %{"id" => id}, socket) do
    usuario = Cuentas.obtener_usuario!(id)
    {:ok, usuario_actualizado} = Cuentas.toggle_activo(usuario)

    if not usuario_actualizado.activo do
      Phoenix.PubSub.broadcast(AzarApp.PubSub, "usuario:#{id}", :forzar_logout)
    end

    base = refrescar_base(socket.assigns.query)
    usuarios = aplicar_filtros(base, socket.assigns.filtros)

    {:noreply,
     socket
     |> assign(usuarios_base: base, usuarios: usuarios)
     |> put_flash(:info, "Usuario #{if usuario_actualizado.activo, do: "activado", else: "desactivado"}")}
  end

  @impl true
  def handle_event("eliminar", %{"id" => id}, socket) do
    usuario = Cuentas.obtener_usuario!(id)

    case Cuentas.eliminar_usuario(usuario) do
      {:error, msg} ->
        {:noreply, put_flash(socket, :error, "❌ #{msg}")}
      {:ok, _} ->
        Phoenix.PubSub.broadcast(AzarApp.PubSub, "usuario:#{id}", :forzar_logout)
        base = refrescar_base(socket.assigns.query)
        usuarios = aplicar_filtros(base, socket.assigns.filtros)
        {:noreply,
         socket
         |> assign(usuarios_base: base, usuarios: usuarios)
         |> put_flash(:info, "Usuario eliminado correctamente.")}
    end
  end

  # ---- HELPERS ----

  defp filtros_default, do: %{estado: "todos", orden: "reciente"}
  defp filtros_activos?(f), do: f != filtros_default()

  defp refrescar_base(""), do: Cuentas.list_usuarios()
  defp refrescar_base(q), do: if(String.trim(q) == "", do: Cuentas.list_usuarios(), else: Cuentas.buscar_usuarios(q))

  defp aplicar_filtros(usuarios, filtros) do
    usuarios
    |> filtrar_estado(filtros.estado)
    |> ordenar(filtros.orden)
  end

  defp filtrar_estado(us, "todos"), do: us
  defp filtrar_estado(us, "activo"), do: Enum.filter(us, & &1.activo)
  defp filtrar_estado(us, "inactivo"), do: Enum.filter(us, &(not &1.activo))

  defp ordenar(us, "reciente"), do: Enum.sort_by(us, & &1.inserted_at, {:desc, NaiveDateTime})
  defp ordenar(us, "antiguo"), do: Enum.sort_by(us, & &1.inserted_at, NaiveDateTime)
  defp ordenar(us, "nombre_az"), do: Enum.sort_by(us, &String.downcase(&1.nombre))
  defp ordenar(us, "nombre_za"), do: Enum.sort_by(us, &String.downcase(&1.nombre), :desc)
  defp ordenar(us, "saldo_desc"), do: Enum.sort_by(us, & &1.saldo_virtual, {:desc, Decimal})
  defp ordenar(us, "saldo_asc"), do: Enum.sort_by(us, & &1.saldo_virtual, Decimal)
  defp ordenar(us, _), do: us

  @impl true
  def render(assigns) do
    ~H"""
    <AzarAppWeb.AdminSidebar.sidebar current_page="usuarios">
      <div class="w-full animate-in fade-in duration-700 relative z-10">

        <%!-- HEADER --%>
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-8">
          <div class="flex flex-col gap-2">
            <div class="inline-flex items-center gap-2 bg-secondary/10 px-4 py-2 rounded-full border border-secondary/20 w-fit">
              <.icon name="hero-users-solid" class="size-4 text-secondary" />
              <span class="text-[10px] font-black uppercase tracking-[0.3em] text-secondary">Administración</span>
            </div>
            <h1 class="text-4xl md:text-5xl font-black italic uppercase tracking-tighter text-base-content mt-1">
              Panel de <span class="text-secondary drop-shadow-md">Clientes</span>
            </h1>
            <p class="text-xs font-bold opacity-40 uppercase tracking-[0.2em] mt-1">
              <%= length(@usuarios) %> de <%= @total %> usuarios
            </p>
          </div>
        </div>

        <%!-- BÚSQUEDA + FILTRO --%>
        <div class="bg-base-100/80 backdrop-blur-xl p-4 rounded-[2rem] border border-base-200/60 shadow-xl mb-4">
          <div class="flex gap-3">
            <form phx-change="buscar" phx-submit="buscar" class="relative flex-1">
              <div class="absolute inset-y-0 left-5 flex items-center pointer-events-none text-base-content/30">
                <.icon name="hero-magnifying-glass-solid" class="size-5" />
              </div>
              <input type="text" name="q" value={@query} placeholder="Buscar por nombre, correo o cédula..."
                phx-debounce="300"
                class="input w-full h-14 pl-14 bg-base-200/50 border-none focus:bg-base-100 focus:ring-2 focus:ring-secondary/50 transition-all rounded-2xl font-bold" />
              <%= if @query != "" do %>
                <button type="button" phx-click="buscar" phx-value-q=""
                  class="absolute inset-y-0 right-4 flex items-center text-base-content/30 hover:text-base-content">
                  <.icon name="hero-x-mark-solid" class="size-5" />
                </button>
              <% end %>
            </form>

            <button phx-click="toggle_filtros"
              class={[
                "btn h-14 w-14 rounded-2xl border transition-all relative shrink-0",
                if(@show_filtros,
                  do: "btn-secondary shadow-lg shadow-secondary/20",
                  else: "bg-base-200/50 border-base-300/50 hover:border-secondary/30 hover:bg-secondary/5")
              ]}>
              <.icon name="hero-funnel-solid" class="size-5" />
              <%= if filtros_activos?(@filtros) do %>
                <span class="absolute -top-1.5 -right-1.5 size-4 bg-warning rounded-full border-2 border-base-100 animate-pulse"></span>
              <% end %>
            </button>
          </div>

          <%!-- PANEL FILTROS --%>
          <%= if @show_filtros do %>
            <form phx-change="filtrar" class="mt-4 pt-4 border-t border-base-200/60 animate-in slide-in-from-top-2 duration-200">
              <div class="grid grid-cols-2 gap-3">
                <div class="flex flex-col gap-1.5">
                  <label class="text-[9px] font-black uppercase tracking-widest text-base-content/40 ml-1">Estado</label>
                  <select name="estado" class="select select-bordered h-11 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-secondary/30 font-bold text-sm">
                    <option value="todos" selected={@filtros.estado == "todos"}>Todos</option>
                    <option value="activo" selected={@filtros.estado == "activo"}>Activos</option>
                    <option value="inactivo" selected={@filtros.estado == "inactivo"}>Inactivos</option>
                  </select>
                </div>
                <div class="flex flex-col gap-1.5">
                  <label class="text-[9px] font-black uppercase tracking-widest text-base-content/40 ml-1">Ordenar por</label>
                  <select name="orden" class="select select-bordered h-11 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-secondary/30 font-bold text-sm">
                    <option value="reciente" selected={@filtros.orden == "reciente"}>Más reciente</option>
                    <option value="antiguo" selected={@filtros.orden == "antiguo"}>Más antiguo</option>
                    <option value="nombre_az" selected={@filtros.orden == "nombre_az"}>Nombre A→Z</option>
                    <option value="nombre_za" selected={@filtros.orden == "nombre_za"}>Nombre Z→A</option>
                    <option value="saldo_desc" selected={@filtros.orden == "saldo_desc"}>Mayor saldo</option>
                    <option value="saldo_asc" selected={@filtros.orden == "saldo_asc"}>Menor saldo</option>
                  </select>
                </div>
              </div>
              <%= if filtros_activos?(@filtros) do %>
                <div class="mt-3 flex justify-end">
                  <button type="button" phx-click="limpiar_filtros"
                    class="btn btn-ghost btn-sm rounded-xl font-black text-[9px] uppercase tracking-widest text-error hover:bg-error/10 gap-1.5">
                    <.icon name="hero-x-mark-solid" class="size-3.5" /> Limpiar
                  </button>
                </div>
              <% end %>
            </form>
          <% end %>
        </div>

        <%!-- LISTA --%>
        <%= if Enum.empty?(@usuarios) do %>
          <div class="h-[40vh] bg-base-100/50 border-2 border-dashed border-base-300/50 rounded-[3rem] flex flex-col items-center justify-center text-base-content/40">
            <.icon name="hero-user-slash-solid" class="size-16 mb-4 opacity-20" />
            <p class="font-black text-xl uppercase tracking-tighter italic">Sin resultados</p>
            <p class="text-[10px] font-bold uppercase tracking-widest mt-2">Ajusta los filtros o la búsqueda</p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
            <div :for={usuario <- @usuarios}
              class="bg-base-100/80 backdrop-blur-xl shadow-xl hover:shadow-2xl border border-base-200/60 hover:border-secondary/30 transition-all duration-500 rounded-[2.5rem] group relative overflow-hidden flex flex-col">
              <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-secondary/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
              <div class="p-7 flex flex-col h-full gap-4">
                <div class="flex items-center justify-between gap-4">
                  <div class="flex items-center gap-4">
                    <div class="size-14 rounded-[1.25rem] bg-secondary/10 border border-secondary/20 text-secondary flex items-center justify-center font-black text-2xl uppercase shadow-inner shrink-0">
                      <%= String.first(usuario.nombre) %>
                    </div>
                    <div>
                      <p class="font-black text-lg uppercase tracking-tight italic text-base-content leading-tight line-clamp-1"><%= usuario.nombre %></p>
                      <p class="text-[10px] font-bold text-base-content/40 uppercase tracking-wider mt-0.5"><%= usuario.cedula %></p>
                    </div>
                  </div>
                  <div class={[
                    "px-3 py-1.5 rounded-xl font-black text-[9px] uppercase tracking-widest border shadow-sm shrink-0",
                    if(usuario.activo, do: "bg-success/10 text-success border-success/20", else: "bg-error/10 text-error border-error/20")
                  ]}>
                    <%= if usuario.activo, do: "Activo", else: "Inactivo" %>
                  </div>
                </div>
                <div class="w-full h-px bg-gradient-to-r from-transparent via-base-300/50 to-transparent"></div>
                <div class="space-y-2">
                  <div class="flex items-center gap-3 text-base-content/60">
                    <.icon name="hero-envelope-solid" class="size-4 shrink-0" />
                    <span class="text-xs font-bold truncate"><%= usuario.email %></span>
                  </div>
                  <div class="flex items-center gap-3 text-base-content/60">
                    <.icon name="hero-wallet-solid" class="size-4 shrink-0 text-success" />
                    <span class="text-xs font-black text-success">$<%= usuario.saldo_virtual || 0 %> saldo</span>
                  </div>
                </div>
                <div class="flex gap-3 mt-auto pt-2">
                  <button phx-click="toggle_activo" phx-value-id={usuario.id}
                    data-confirm={"¿#{if usuario.activo, do: "Desactivar", else: "Activar"} este usuario?"}
                    class={[
                      "btn btn-sm flex-1 rounded-xl font-black text-[9px] uppercase tracking-widest border transition-all",
                      if(usuario.activo,
                        do: "bg-error/10 text-error border-error/20 hover:bg-error hover:text-white",
                        else: "bg-success/10 text-success border-success/20 hover:bg-success hover:text-white")
                    ]}>
                    <%= if usuario.activo, do: "Desactivar", else: "Activar" %>
                  </button>
                  <button phx-click="eliminar" phx-value-id={usuario.id}
                    data-confirm="¿Eliminar este usuario permanentemente?"
                    class="btn btn-sm btn-circle bg-error/10 text-error border border-error/20 hover:bg-error hover:text-white rounded-xl transition-all">
                    <.icon name="hero-trash-solid" class="size-3.5" />
                  </button>
                  <.link navigate={~p"/admin/usuarios/#{usuario.id}"}
                    class="btn btn-secondary btn-sm flex-[2] rounded-xl shadow-md shadow-secondary/20 hover:-translate-y-0.5 transition-transform font-black text-[9px] uppercase tracking-widest gap-2">
                    Gestionar <.icon name="hero-arrow-right-circle-solid" class="size-4" />
                  </.link>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </AzarAppWeb.AdminSidebar.sidebar>
    """
  end
end
