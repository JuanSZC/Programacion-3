defmodule AzarAppWeb.Admin.UsuarioLive.Index do
  use AzarAppWeb, :live_view
  alias AzarApp.Cuentas

  @impl true
  def mount(_params, _session, socket) do
    usuarios = Cuentas.list_usuarios()
    {:ok,
     socket
     |> assign(:usuarios, usuarios)
     |> assign(:query, "")
     |> assign(:total, length(usuarios))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Gestión de Clientes")}
  end

  @impl true
  def handle_event("buscar", %{"q" => q}, socket) do
    usuarios = if String.trim(q) == "", do: Cuentas.list_usuarios(), else: Cuentas.buscar_usuarios(q)
    {:noreply, assign(socket, usuarios: usuarios, query: q)}
  end

@impl true
def handle_event("toggle_activo", %{"id" => id}, socket) do
  usuario = Cuentas.obtener_usuario!(id)
  {:ok, usuario_actualizado} = Cuentas.toggle_activo(usuario)

  # Si se desactivó, forzar cierre de sesión
  if not usuario_actualizado.activo do
    Phoenix.PubSub.broadcast(AzarApp.PubSub, "usuario:#{id}", :forzar_logout)
  end

  usuarios = if String.trim(socket.assigns.query) == "",
    do: Cuentas.list_usuarios(),
    else: Cuentas.buscar_usuarios(socket.assigns.query)

  {:noreply,
   socket
   |> assign(:usuarios, usuarios)
   |> put_flash(:info, "Usuario #{if usuario_actualizado.activo, do: "activado", else: "desactivado"}")}
end

@impl true
def handle_event("eliminar", %{"id" => id}, socket) do
  usuario = Cuentas.obtener_usuario!(id)

  if Cuentas.tiene_tickets_activos?(usuario.id) do
    {:noreply, put_flash(socket, :error, "❌ No se puede eliminar: el usuario tiene tickets en sorteos activos.")}
  else
    Phoenix.PubSub.broadcast(AzarApp.PubSub, "usuario:#{id}", :forzar_logout)
    {:ok, _} = Cuentas.eliminar_usuario(usuario)

    usuarios = if String.trim(socket.assigns.query) == "",
      do: Cuentas.list_usuarios(),
      else: Cuentas.buscar_usuarios(socket.assigns.query)

    {:noreply,
     socket
     |> assign(:usuarios, usuarios)
     |> put_flash(:info, "Usuario eliminado correctamente.")}
  end
end


  @impl true
  def render(assigns) do
    ~H"""
    <AzarAppWeb.AdminSidebar.sidebar current_page="usuarios">
      <div class="w-full animate-in fade-in duration-700 relative z-10">

        <%!-- HEADER --%>
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-10">
          <div class="flex flex-col gap-2">
            <div class="inline-flex items-center gap-2 bg-secondary/10 px-4 py-2 rounded-full border border-secondary/20 w-fit">
              <.icon name="hero-users-solid" class="size-4 text-secondary" />
              <span class="text-[10px] font-black uppercase tracking-[0.3em] text-secondary">Administración</span>
            </div>
            <h1 class="text-4xl md:text-5xl font-black italic uppercase tracking-tighter text-base-content mt-1">
              Panel de <span class="text-secondary drop-shadow-md">Clientes</span>
            </h1>
            <p class="text-xs font-bold opacity-40 uppercase tracking-[0.2em] mt-1">
              <%= @total %> usuarios registrados en la plataforma
            </p>
          </div>
        </div>

        <%!-- BARRA DE BÚSQUEDA --%>
        <div class="bg-base-100/80 backdrop-blur-xl p-4 rounded-[2rem] border border-base-200/60 shadow-xl mb-8">
          <form phx-change="buscar" phx-submit="buscar" class="relative">
            <div class="absolute inset-y-0 left-5 flex items-center pointer-events-none text-base-content/30">
              <.icon name="hero-magnifying-glass-solid" class="size-5" />
            </div>
            <input
              type="text"
              name="q"
              value={@query}
              placeholder="Buscar por nombre, correo o cédula..."
              phx-debounce="300"
              class="input w-full h-14 pl-14 bg-base-200/50 border-none focus:bg-base-100 focus:ring-2 focus:ring-secondary/50 transition-all rounded-2xl font-bold text-base-content"
            />
            <%= if @query != "" do %>
              <button type="button" phx-click="buscar" phx-value-q="" class="absolute inset-y-0 right-4 flex items-center text-base-content/30 hover:text-base-content transition-colors">
                <.icon name="hero-x-mark-solid" class="size-5" />
              </button>
            <% end %>
          </form>
        </div>

        <%!-- LISTA DE USUARIOS --%>
        <%= if Enum.empty?(@usuarios) do %>
          <div class="h-[40vh] bg-base-100/50 border-2 border-dashed border-base-300/50 rounded-[3rem] flex flex-col items-center justify-center text-base-content/40">
            <.icon name="hero-user-slash-solid" class="size-16 mb-4 opacity-20" />
            <p class="font-black text-xl uppercase tracking-tighter italic">Sin resultados</p>
            <p class="text-[10px] font-bold uppercase tracking-widest mt-2">Intenta con otro término de búsqueda</p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
            <div :for={usuario <- @usuarios}
              class="bg-base-100/80 backdrop-blur-xl shadow-xl hover:shadow-2xl border border-base-200/60 hover:border-secondary/30 transition-all duration-500 rounded-[2.5rem] group relative overflow-hidden flex flex-col">

              <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-secondary/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>

              <div class="p-7 flex flex-col h-full gap-4">

                <%!-- Avatar + Nombre + Estado --%>
                <div class="flex items-center justify-between gap-4">
                  <div class="flex items-center gap-4">
                    <div class="size-14 rounded-[1.25rem] bg-secondary/10 border border-secondary/20 text-secondary flex items-center justify-center font-black text-2xl uppercase shadow-inner shrink-0">
                      <%= String.first(usuario.nombre) %>
                    </div>
                    <div>
                      <p class="font-black text-lg uppercase tracking-tight italic text-base-content leading-tight line-clamp-1">
                        <%= usuario.nombre %>
                      </p>
                      <p class="text-[10px] font-bold text-base-content/40 uppercase tracking-wider mt-0.5">
                        <%= usuario.cedula %>
                      </p>
                    </div>
                  </div>

                  <div class={[
                    "px-3 py-1.5 rounded-xl font-black text-[9px] uppercase tracking-widest border shadow-sm shrink-0",
                    if(usuario.activo,
                      do: "bg-success/10 text-success border-success/20",
                      else: "bg-error/10 text-error border-error/20")
                  ]}>
                    <%= if usuario.activo, do: "Activo", else: "Inactivo" %>
                  </div>
                </div>

                <div class="w-full h-px bg-gradient-to-r from-transparent via-base-300/50 to-transparent"></div>

                <%!-- Datos clave --%>
                <div class="space-y-2">
                  <div class="flex items-center gap-3 text-base-content/60">
                    <.icon name="hero-envelope-solid" class="size-4 shrink-0" />
                    <span class="text-xs font-bold truncate"><%= usuario.email %></span>
                  </div>
                  <div class="flex items-center gap-3 text-base-content/60">
                    <.icon name="hero-wallet-solid" class="size-4 shrink-0 text-success" />
                    <span class="text-xs font-black text-success">$<%= usuario.saldo_virtual || 0 %> saldo</span>
                  </div>
                  <div class="flex items-center gap-3 text-base-content/60">
                    <.icon name="hero-shield-check-solid" class="size-4 shrink-0" />
                    <span class="text-[10px] font-black uppercase tracking-widest"><%= usuario.rol %></span>
                  </div>
                </div>

                <%!-- Acciones --%>
                <div class="flex gap-3 mt-auto pt-2">
                  <button
                    phx-click="toggle_activo"
                    phx-value-id={usuario.id}
                    data-confirm={"¿#{if usuario.activo, do: "Desactivar", else: "Activar"} este usuario?"}
                    class={[
                      "btn btn-sm flex-1 rounded-xl font-black text-[9px] uppercase tracking-widest border transition-all",
                      if(usuario.activo,
                        do: "bg-error/10 text-error border-error/20 hover:bg-error hover:text-white",
                        else: "bg-success/10 text-success border-success/20 hover:bg-success hover:text-white")
                    ]}>
                    <%= if usuario.activo, do: "Desactivar", else: "Activar" %>
                  </button>

                  <button
                    phx-click="eliminar"
                    phx-value-id={usuario.id}
                    data-confirm="¿Eliminar este usuario permanentemente?"
                    class="btn btn-sm btn-circle bg-error/10 text-error border border-error/20 hover:bg-error hover:text-white rounded-xl transition-all">
                    <.icon name="hero-trash-solid" class="size-3.5" />
                  </button>
                  <.link navigate={~p"/admin/usuarios/#{usuario.id}"}
                    class="btn btn-secondary btn-sm flex-[2] rounded-xl shadow-md shadow-secondary/20 hover:-translate-y-0.5 transition-transform font-black text-[9px] uppercase tracking-widest gap-2">
                    Gestionar
                    <.icon name="hero-arrow-right-circle-solid" class="size-4" />
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
