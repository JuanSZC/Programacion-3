defmodule AzarAppWeb.AdminSidebar do
  @moduledoc """
  Módulo AzarAppWeb.AdminSidebar: lógica relacionada con adminsidebar.
  """

  use AzarAppWeb, :html

  attr(:current_page, :string, default: "sorteos")
  slot(:inner_block, required: true)

  @doc """
  Breve: sidebar.
  """
  def sidebar(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open min-h-screen bg-base-200/40 overflow-hidden">
      <input id="admin-sidebar-drawer" type="checkbox" class="drawer-toggle" />

      <div class="drawer-content flex flex-col min-h-screen">

        <!-- NAVBAR MOBILE -->
        <div class="navbar lg:hidden sticky top-0 z-30 border-b border-base-300/60 bg-base-100/80 backdrop-blur-xl">
          <div class="flex-none">
            <label for="admin-sidebar-drawer" class="btn btn-square btn-ghost rounded-2xl" aria-label="Abrir menú">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="size-6 stroke-current">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
              </svg>
            </label>
          </div>
          <div class="flex-1 px-2">
            <div class="flex items-center gap-2">
              <div class="bg-primary p-2 rounded-xl shadow-lg shadow-primary/20">
                <.icon name="hero-bolt-solid" class="size-4 text-white" />
              </div>
              <span class="text-lg font-black italic tracking-tight uppercase text-primary">
                Azar <span class="text-base-content/30">Admin</span>
              </span>
            </div>
          </div>
        </div>

        <!-- MAIN -->
        <main class="flex-1 p-4 lg:p-8 overflow-y-auto">
          <div class="max-w-7xl mx-auto w-full">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>

      <div class="drawer-side z-40">
        <label for="admin-sidebar-drawer" aria-label="Cerrar menú" class="drawer-overlay"></label>

        <aside class="w-80 min-h-full bg-base-100 border-r border-base-300/60 flex flex-col">

          <!-- HEADER -->
          <div class="h-24 px-6 border-b border-base-300/50 flex items-center justify-between bg-base-100/90 backdrop-blur-md">
            <div class="flex items-center gap-3">
              <div class="bg-primary p-3 rounded-2xl shadow-xl shadow-primary/20">
                <.icon name="hero-bolt-solid" class="size-6 text-white" />
              </div>
              <div class="leading-tight">
                <h1 class="text-3xl font-black italic uppercase tracking-tighter text-primary">Azar</h1>
                <span class="text-[10px] uppercase tracking-[0.35em] text-base-content/40 font-black">
                  Administration Panel
                </span>
              </div>
            </div>
            <label for="admin-sidebar-drawer" class="btn btn-sm btn-circle btn-ghost lg:hidden" aria-label="Cerrar menú">
              ✕
            </label>
          </div>

          <!-- MENU -->
          <div class="flex-1 overflow-y-auto px-4 py-6">
            <div class="mb-4 px-4">
              <span class="text-[10px] uppercase tracking-[0.35em] text-base-content/30 font-black">
                Administración
              </span>
            </div>

            <ul class="menu gap-2 w-full">

              <li>
                <.link navigate={~p"/admin/sorteos"} class={menu_class(@current_page == "sorteos", "primary")}>
                  <div class={icon_container(@current_page == "sorteos")}>
                    <.icon name="hero-ticket-solid" class="size-5 transition-transform group-hover:scale-110" />
                  </div>
                  <div class="flex flex-col">
                    <span class="text-sm uppercase tracking-wide font-black">Sorteos</span>
                    <span class="text-[10px] opacity-60 font-semibold">Gestión y control</span>
                  </div>
                </.link>
              </li>

              <li>
                <.link navigate={~p"/admin/usuarios"} class={menu_class(@current_page == "usuarios", "secondary")}>
                  <div class={icon_container(@current_page == "usuarios")}>
                    <.icon name="hero-users-solid" class="size-5 transition-transform group-hover:scale-110" />
                  </div>
                  <div class="flex flex-col">
                    <span class="text-sm uppercase tracking-wide font-black">Clientes</span>
                    <span class="text-[10px] opacity-60 font-semibold">Usuarios registrados</span>
                  </div>
                </.link>
              </li>

              <li>
                <.link navigate={~p"/admin/dashboard"} class={menu_class(@current_page == "dashboard", "warning")}>
                  <div class={icon_container(@current_page == "dashboard")}>
                    <.icon name="hero-chart-bar-solid" class="size-5 transition-transform group-hover:scale-110" />
                  </div>
                  <div class="flex flex-col flex-1">
                    <span class="text-sm uppercase tracking-wide font-black">Analytics</span>
                    <span class="text-[10px] opacity-60 font-semibold">Estadísticas y métricas</span>
                  </div>
                  <span class="badge badge-warning badge-sm font-black uppercase">Live</span>
                </.link>
              </li>

            </ul>
          </div>

          <!-- FOOTER -->
          <div class="border-t border-base-300/50 p-4 bg-base-100 flex flex-col gap-3">

            <.link
              navigate={~p"/admin/perfil"}
              class={[
                "group rounded-3xl border p-4 flex items-center gap-3 transition-all duration-300",
                if(@current_page == "perfil",
                  do: "border-primary/30 bg-primary/10",
                  else: "border-base-300/40 bg-base-200/40 hover:border-primary/20 hover:bg-primary/5")
              ]}
            >
              <div class="avatar placeholder">
                <div class={[
                  "rounded-2xl w-12 transition-all",
                  if(@current_page == "perfil",
                    do: "bg-primary text-primary-content shadow-lg shadow-primary/30",
                    else: "bg-primary/20 text-primary group-hover:bg-primary group-hover:text-white")
                ]}>
                  <span class="font-black text-sm">AD</span>
                </div>
              </div>
              <div class="flex flex-col flex-1">
                <span class="text-xs font-black uppercase tracking-wide group-hover:text-primary transition-colors">
                  Administrador
                </span>
                <span class="text-[10px] text-success uppercase flex items-center gap-1 font-bold">
                  <div class="size-2 rounded-full bg-success animate-pulse"></div>
                  En línea · Ver perfil
                </span>
              </div>
              <.icon name="hero-chevron-right-solid" class="size-4 text-base-content/20 group-hover:text-primary transition-colors" />
            </.link>

            <.link
              href={~p"/sesion"}
              method="delete"
              class="group flex items-center justify-between rounded-2xl border border-error/20 bg-error/5 px-5 py-4 text-error transition-all duration-300 hover:bg-error/10 hover:border-error/40"
            >
              <div class="flex items-center gap-3">
                <.icon name="hero-arrow-right-on-rectangle-solid" class="size-5 transition-transform group-hover:translate-x-1" />
                <span class="text-xs uppercase tracking-[0.2em] font-black">Cerrar sesión</span>
              </div>
              <.icon name="hero-chevron-right-solid" class="size-4 opacity-40 group-hover:opacity-100 transition-opacity" />
            </.link>

          </div>

        </aside>
      </div>
    </div>
    """
  end

  defp menu_class(true, "primary") do
    [
      "group flex items-center gap-4 px-4 py-4 rounded-2xl transition-all duration-300 border font-black",
      "bg-primary text-primary-content border-primary shadow-xl"
    ]
  end

  defp menu_class(true, "secondary") do
    [
      "group flex items-center gap-4 px-4 py-4 rounded-2xl transition-all duration-300 border font-black",
      "bg-secondary text-secondary-content border-secondary shadow-xl"
    ]
  end

  defp menu_class(true, "warning") do
    [
      "group flex items-center gap-4 px-4 py-4 rounded-2xl transition-all duration-300 border font-black",
      "bg-warning text-warning-content border-warning shadow-xl"
    ]
  end

  defp menu_class(false, _color) do
    [
      "group flex items-center gap-4 px-4 py-4 rounded-2xl transition-all duration-300 border",
      "border-transparent hover:border-base-300 hover:bg-base-200/70",
      "text-base-content/70 hover:text-base-content"
    ]
  end

  defp icon_container(true), do: "p-2 rounded-xl bg-white/10 transition-all"
  defp icon_container(false), do: "p-2 rounded-xl transition-all"
end
