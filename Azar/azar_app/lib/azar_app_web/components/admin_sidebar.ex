defmodule AzarAppWeb.AdminSidebar do
  use AzarAppWeb, :html

  attr :current_page, :string, default: "sorteos"
  slot :inner_block, required: true

  def sidebar(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open">
      <input id="my-drawer-2" type="checkbox" class="drawer-toggle" />

      <div class="drawer-content flex flex-col bg-base-200/30">
        <%!-- NAVBAR MÓVIL --%>
        <div class="navbar bg-base-100/80 backdrop-blur-md border-b border-base-300 sticky top-0 z-40 lg:hidden">
          <div class="flex-none">
            <label for="my-drawer-2" class="btn btn-square btn-ghost">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-6 h-6 stroke-current">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
              </svg>
            </label>
          </div>
          <div class="flex-1 px-2 mx-2">
            <span class="text-xl font-black text-primary tracking-tight italic uppercase">Azar Admin</span>
          </div>
        </div>

        <main class="flex-1 p-4 lg:p-8">
          <div class="max-w-7xl mx-auto w-full">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>

      <div class="drawer-side z-50">
        <label for="my-drawer-2" aria-label="close sidebar" class="drawer-overlay"></label>

        <div class="flex flex-col w-80 min-h-full bg-base-100 border-r border-base-300 shadow-sm">
          <%!-- LOGO SECCIÓN --%>
          <div class="h-24 flex items-center px-8 border-b border-base-200 bg-base-100">
            <div class="flex items-center gap-2">
              <div class="bg-primary p-2 rounded-xl shadow-lg shadow-primary/20">
                <.icon name="hero-bolt-solid" class="size-6 text-white" />
              </div>
              <h2 class="text-3xl font-black text-primary tracking-tighter italic uppercase">
                Azar<span class="text-base-content/20">App</span>
              </h2>
            </div>
          </div>

          <%!-- MENÚ DE NAVEGACIÓN --%>
          <ul class="menu flex-1 px-4 py-8 space-y-2 text-base font-medium">
            <li class="menu-title text-[10px] uppercase tracking-[0.3em] text-base-content/30 font-black mb-4 px-4">
              Administración
            </li>

            <li>
              <.link navigate={~p"/admin/sorteos"} class={[
                "flex items-center gap-3 px-4 py-4 rounded-2xl transition-all duration-300 group",
                @current_page == "sorteos" && "bg-primary text-primary-content shadow-xl shadow-primary/30 font-black italic",
                @current_page != "sorteos" && "text-base-content/60 hover:bg-base-200 hover:text-base-content"
              ]}>
                <.icon name="hero-ticket-solid" class={["size-5 transition-transform group-hover:scale-110", @current_page == "sorteos" && "text-white"]} />
                <span>Gestión de Sorteos</span>
              </.link>
            </li>

            <%!-- Agrega aquí más ítems de menú si los necesitas --%>
          </ul>

          <%!-- SECCIÓN INFERIOR: PERFIL Y LOGOUT --%>
          <div class="p-4 border-t border-base-200 bg-base-50">
            <div class="flex flex-col gap-2">
              <%!-- INFO DEL ADMIN --%>
              <div class="flex items-center gap-3 px-4 py-4 rounded-2xl bg-base-200/50 border border-base-300/30">
                <div class="avatar placeholder">
                  <div class="bg-primary text-primary-content rounded-xl w-10 shadow-md">
                    <span class="font-black text-xs uppercase">AD</span>
                  </div>
                </div>
                <div class="flex flex-col">
                  <span class="text-xs font-black text-base-content uppercase tracking-tighter italic">Administrador</span>
                  <span class="text-[10px] font-bold text-success flex items-center gap-1 uppercase">
                    <div class="size-1.5 bg-success rounded-full animate-pulse"></div> En línea
                  </span>
                </div>
              </div>

              <%!-- BOTÓN CERRAR SESIÓN CHIMBA --%>
              <.link
                href={~p"/sesion"}
                method="delete"
                class="flex items-center justify-between px-5 py-4 rounded-2xl text-error font-black text-xs uppercase tracking-widest hover:bg-error/10 border border-transparent hover:border-error/20 transition-all group"
              >
                <div class="flex items-center gap-3">
                  <.icon name="hero-arrow-right-on-rectangle" class="size-5 transition-transform group-hover:translate-x-1" />
                  Cerrar Sesión
                </div>
                <.icon name="hero-chevron-right" class="size-3 opacity-0 group-hover:opacity-100 transition-opacity" />
              </.link>
            </div>
          </div>

        </div>
      </div>
    </div>
    """
  end
end
