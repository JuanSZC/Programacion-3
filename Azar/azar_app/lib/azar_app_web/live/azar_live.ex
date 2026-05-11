defmodule AzarAppWeb.AzarLive do
  use AzarAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="relative py-12 flex flex-col items-center justify-center min-h-[80vh]">

      <%!-- BOTÓN DE CAMBIO DE TEMA (Esquina superior derecha) --%>
      <div class="absolute top-0 right-4 sm:right-8 z-50 scale-110 shadow-lg rounded-full">
        <AzarAppWeb.Layouts.theme_toggle />
      </div>

      <div class="max-w-4xl w-full text-center space-y-12 mt-8">

        <%!-- HEADER DE BIENVENIDA --%>
        <div class="relative">
          <div class="absolute -top-6 left-1/2 -translate-x-1/2 w-24 h-1 bg-primary rounded-full opacity-20"></div>
          <h1 class="text-6xl font-black text-base-content tracking-tighter">
            Azar <span class="text-primary tracking-tight">UQ Pro</span>
          </h1>
          <p class="text-xl text-base-content/60 font-medium mt-4">
            Gestión inteligente y transparente de sorteos
          </p>
        </div>

        <%!-- GRID DE OPCIONES --%>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 px-4">

          <%!-- CARD ADMINISTRADOR --%>
          <.link
            navigate={~p"/admin/login"}
            class="group relative overflow-hidden p-8 bg-base-200/50 backdrop-blur-sm border border-base-300 rounded-[2.5rem] hover:border-primary hover:shadow-2xl hover:shadow-primary/10 hover:-translate-y-2 transition-all duration-500"
          >
            <div class="relative z-10 flex flex-col items-center space-y-5">
              <div class="p-6 bg-primary text-primary-content rounded-3xl shadow-lg shadow-primary/30 group-hover:rotate-6 transition-transform duration-500">
                <.icon name="hero-cog-8-tooth" class="size-10" />
              </div>
              <div class="text-center">
                <h2 class="text-2xl font-black text-base-content uppercase tracking-tight">Administración</h2>
                <p class="text-sm text-base-content/60 mt-2 leading-relaxed">
                  Configura sorteos, controla el bombo digital y genera reportes de cumplimiento.
                </p>
              </div>
              <span class="btn btn-primary btn-sm rounded-xl px-6 opacity-0 group-hover:opacity-100 transition-opacity">
                Acceder al Panel
              </span>
            </div>
          </.link>

          <%!-- CARD CLIENTE --%>
          <.link
            navigate={~p"/login"}
            class="group relative overflow-hidden p-8 bg-base-200/50 backdrop-blur-sm border border-base-300 rounded-[2.5rem] hover:border-secondary hover:shadow-2xl hover:shadow-secondary/10 hover:-translate-y-2 transition-all duration-500"
          >
            <div class="relative z-10 flex flex-col items-center space-y-5">
              <div class="p-6 bg-secondary text-secondary-content rounded-3xl shadow-lg shadow-secondary/30 group-hover:-rotate-6 transition-transform duration-500">
                <.icon name="hero-ticket" class="size-10" />
              </div>
              <div class="text-center">
                <h2 class="text-2xl font-black text-base-content uppercase tracking-tight">Portal Cliente</h2>
                <p class="text-sm text-base-content/60 mt-2 leading-relaxed">
                  Compra tus tickets, verifica resultados y gestiona tus premios ganados.
                </p>
              </div>
              <span class="btn btn-secondary btn-sm rounded-xl px-6 opacity-0 group-hover:opacity-100 transition-opacity">
                Participar Ahora
              </span>
            </div>
          </.link>

        </div>

        <%!-- FOOTER DE CONFIANZA --%>
        <div class="pt-8 border-t border-base-200 max-w-xs mx-auto">
          <div class="flex items-center justify-center gap-4 text-base-content/30 italic font-medium">
             <.icon name="hero-shield-check" class="size-5" />
             <span>Encriptación de grado militar</span>
          </div>
        </div>

      </div>
    </div>
    """
  end
end
