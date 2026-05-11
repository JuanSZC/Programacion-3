defmodule AzarAppWeb.AdminSidebar do
  use AzarAppWeb, :html

  attr :current_page, :string, default: "sorteos"

  slot :inner_block, required: true

  def sidebar(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open">
      <input id="my-drawer-2" type="checkbox" class="drawer-toggle" />

      <div class="drawer-content flex flex-col bg-base-200/30">

        <div class="navbar bg-base-100/80 backdrop-blur-md border-b border-base-300 sticky top-0 z-40 lg:hidden">
          <div class="flex-none">
            <label for="my-drawer-2" class="btn btn-square btn-ghost">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-6 h-6 stroke-current">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
              </svg>
            </label>
          </div>
          <div class="flex-1 px-2 mx-2">
            <span class="text-xl font-black text-primary tracking-tight">Azar Admin</span>
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

          <div class="h-20 flex items-center px-8 border-b border-base-200">
            <h2 class="text-3xl font-black text-primary tracking-tighter">
              Azar<span class="text-base-content/20">.</span>
            </h2>
          </div>

          <ul class="menu flex-1 px-4 py-6 space-y-2 text-base font-medium">
            <li class="menu-title text-xs uppercase tracking-widest text-base-content/40 font-bold mb-2 px-4">
              Administración
            </li>

            <li>
              <a href="/admin/sorteos" class={[
                "flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200",
                @current_page == "sorteos" && "bg-primary text-primary-content shadow-md shadow-primary/20",
                @current_page != "sorteos" && "text-base-content/70 hover:bg-base-200 hover:text-base-content"
              ]}>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm3.5-9c.83 0 1.5-.67 1.5-1.5S16.33 8 15.5 8 14 8.67 14 9.5s.67 1.5 1.5 1.5zm-7 0c.83 0 1.5-.67 1.5-1.5S9.33 8 8.5 8 7 8.67 7 9.5 7.67 11 8.5 11zm3.5 6.5c2.33 0 4.31-1.46 5.11-3.5H6.89c.8 2.04 2.78 3.5 5.11 3.5z"/>
                </svg>
                Sorteos
              </a>
            </li>

            <div class="divider my-4 px-4 opacity-30"></div>

            <li>
              <a href="/" class="flex items-center gap-3 px-4 py-3 rounded-xl text-base-content/70 hover:bg-base-200 hover:text-base-content transition-all duration-200">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
                </svg>
                Volver al Inicio
              </a>
            </li>
          </ul>

          <div class="p-4 border-t border-base-200">
            <div class="flex items-center gap-3 px-4 py-3 rounded-xl bg-base-200/50 hover:bg-base-200 transition-colors cursor-pointer">
              <div class="avatar placeholder">
                <div class="bg-primary text-primary-content rounded-full w-10">
                  <span class="font-semibold">AD</span>
                </div>
              </div>
              <div class="flex flex-col">
                <span class="text-sm font-bold text-base-content">Admin</span>
                <span class="text-xs text-base-content/50">Panel de Control</span>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
    """
  end
end
