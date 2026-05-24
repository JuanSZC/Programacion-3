defmodule AzarAppWeb.AdminSidebar do
  @moduledoc """
  Sidebar de administración. Limpio, con indicador de página activa sutil.
  """

  use AzarAppWeb, :html

  attr(:current_page, :string, default: "sorteos")
  slot(:inner_block, required: true)

  @doc """
  Componente sidebar para el panel de administración.
  """
  def sidebar(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open min-h-screen bg-base-50">
      <input id="admin-sidebar-drawer" type="checkbox" class="drawer-toggle" />

      <div class="drawer-content flex flex-col min-h-screen">

        <%!-- NAVBAR MOBILE --%>
        <div class="navbar lg:hidden sticky top-0 z-30 bg-base-100/80 backdrop-blur-xl border-b border-base-content/8 px-4 h-14 min-h-0">
          <label
            for="admin-sidebar-drawer"
            class="btn btn-ghost btn-sm rounded-lg px-2"
            aria-label="Abrir menú"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="size-5 stroke-current">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </label>

          <div class="flex-1 flex items-center gap-2 px-3">
            <div class="w-6 h-6 bg-primary rounded-md flex items-center justify-center">
              <.icon name="hero-bolt-solid" class="size-3.5 text-primary-content" />
            </div>
            <span class="font-display font-bold text-base tracking-tight text-base-content">
              Azar <span class="text-base-content/30 font-medium">Admin</span>
            </span>
          </div>
        </div>

        <%!-- MAIN --%>
        <main class="flex-1 p-5 lg:p-8 overflow-y-auto">
          <div class="max-w-7xl mx-auto w-full">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>

      <%!-- SIDEBAR --%>
      <div class="drawer-side z-40">
        <label for="admin-sidebar-drawer" aria-label="Cerrar menú" class="drawer-overlay"></label>

        <aside class="w-64 min-h-full bg-base-100 border-r border-base-content/8 flex flex-col">

          <%!-- HEADER del sidebar --%>
          <div class="h-16 px-5 flex items-center justify-between border-b border-base-content/8">
            <div class="flex items-center gap-2.5">
              <div class="w-7 h-7 bg-primary rounded-lg flex items-center justify-center shadow-sm">
                <.icon name="hero-bolt-solid" class="size-4 text-primary-content" />
              </div>
              <div class="leading-none">
                <span class="font-display font-bold text-base tracking-tight text-base-content">Azar</span>
                <span class="block text-[10px] text-base-content/35 font-medium tracking-wide uppercase mt-0.5">Admin</span>
              </div>
            </div>
            <label
              for="admin-sidebar-drawer"
              class="btn btn-ghost btn-xs rounded-lg lg:hidden"
              aria-label="Cerrar menú"
            >
              <.icon name="hero-x-mark-solid" class="size-4" />
            </label>
          </div>

          <%!-- NAVEGACIÓN --%>
          <div class="flex-1 overflow-y-auto py-4 px-3">
            <p class="px-3 mb-2 text-[10px] font-semibold uppercase tracking-widest text-base-content/30">
              Administración
            </p>

            <nav class="flex flex-col gap-0.5">

              <.nav_item
                href={~p"/admin/sorteos"}
                active={@current_page == "sorteos"}
                icon="hero-ticket-solid"
                label="Sorteos"
                sublabel="Gestión y control"
              />

              <.nav_item
                href={~p"/admin/usuarios"}
                active={@current_page == "usuarios"}
                icon="hero-users-solid"
                label="Clientes"
                sublabel="Usuarios registrados"
              />

              <.nav_item
                href={~p"/admin/dashboard"}
                active={@current_page == "dashboard"}
                icon="hero-chart-bar-solid"
                label="Analytics"
                sublabel="Estadísticas"
              >
                <:badge>
                  <span class="text-[9px] font-bold uppercase tracking-wide px-1.5 py-0.5 rounded-md bg-warning/15 text-warning border border-warning/20">
                    Live
                  </span>
                </:badge>
              </.nav_item>

            </nav>
          </div>

          <%!-- FOOTER del sidebar: perfil + logout --%>
          <div class="border-t border-base-content/8 p-3 flex flex-col gap-1">

            <.link
              navigate={~p"/admin/perfil"}
              class={[
                "group flex items-center gap-3 px-3 py-3 rounded-xl transition-all duration-150",
                if(@current_page == "perfil",
                  do: "bg-primary/8 text-primary",
                  else: "hover:bg-base-content/5 text-base-content/60 hover:text-base-content")
              ]}
            >
              <div class={[
                "w-8 h-8 rounded-lg flex items-center justify-center font-display font-bold text-xs transition-all",
                if(@current_page == "perfil",
                  do: "bg-primary text-primary-content",
                  else: "bg-base-content/8 text-base-content group-hover:bg-primary/10 group-hover:text-primary")
              ]}>
                AD
              </div>
              <div class="flex flex-col flex-1 min-w-0">
                <span class="text-xs font-semibold truncate">Administrador</span>
                <span class="text-[10px] text-success flex items-center gap-1 font-medium">
                  <span class="size-1.5 rounded-full bg-success inline-block animate-pulse"></span>
                  En línea
                </span>
              </div>
              <.icon name="hero-chevron-right-solid" class="size-3.5 opacity-30 group-hover:opacity-60 transition-opacity flex-shrink-0" />
            </.link>

            <.link
              href={~p"/sesion"}
              method="delete"
              class="group flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-error/60 hover:text-error hover:bg-error/6 transition-all duration-150"
            >
              <.icon name="hero-arrow-right-on-rectangle-solid" class="size-4 group-hover:translate-x-0.5 transition-transform" />
              <span class="text-xs font-semibold">Cerrar sesión</span>
            </.link>

          </div>
        </aside>
      </div>
    </div>
    """
  end

  # Componente interno para items de navegación
  attr :href, :string, required: true
  attr :active, :boolean, default: false
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :sublabel, :string, default: nil
  slot :badge

  defp nav_item(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class={[
        "group flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-150 relative",
        if(@active,
          do: "bg-primary/8 text-primary",
          else: "text-base-content/60 hover:text-base-content hover:bg-base-content/5")
      ]}
    >
      <%!-- Indicador lateral activo --%>
      <%= if @active do %>
        <div class="absolute left-0 top-1/2 -translate-y-1/2 w-0.5 h-5 bg-primary rounded-full"></div>
      <% end %>

      <div class={[
        "w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 transition-all",
        if(@active,
          do: "bg-primary/12 text-primary",
          else: "bg-base-content/6 text-base-content/50 group-hover:bg-primary/8 group-hover:text-primary")
      ]}>
        <.icon name={@icon} class="size-4" />
      </div>

      <div class="flex flex-col flex-1 min-w-0">
        <span class="text-xs font-semibold leading-tight"><%= @label %></span>
        <%= if @sublabel do %>
          <span class={["text-[10px] leading-tight mt-0.5 transition-colors",
            if(@active, do: "text-primary/50", else: "text-base-content/35 group-hover:text-base-content/50")
          ]}>
            <%= @sublabel %>
          </span>
        <% end %>
      </div>

      <%= if @badge != [] do %>
        {render_slot(@badge)}
      <% end %>
    </.link>
    """
  end
end
