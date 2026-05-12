defmodule AzarAppWeb.AzarLive do
  use AzarAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="relative flex flex-col items-center justify-center min-h-screen bg-base-100 overflow-hidden">

      <%!-- LUCES DE FONDO (Efecto Glassmorphism / Neomorfismo) --%>
      <div class="absolute top-0 left-0 w-full h-full overflow-hidden -z-10 pointer-events-none">
        <div class="absolute -top-40 -right-40 w-96 h-96 bg-primary/10 rounded-full blur-[100px] animate-pulse"></div>
        <div class="absolute -bottom-40 -left-40 w-96 h-96 bg-secondary/10 rounded-full blur-[100px] animate-pulse" style="animation-delay: 2s;"></div>
      </div>

      <%!-- BOTÓN DE CAMBIO DE TEMA (Esquina superior derecha) --%>
      <div class="absolute top-6 right-6 sm:top-10 sm:right-10 z-50">
        <div class="bg-base-200/80 backdrop-blur-md p-2 rounded-full border border-base-300 shadow-xl hover:scale-110 transition-transform">
          <AzarAppWeb.Layouts.theme_toggle />
        </div>
      </div>

      <div class="max-w-5xl w-full text-center space-y-16 px-6 relative z-10">

        <%!-- HEADER DE BIENVENIDA --%>
        <div class="relative animate-in slide-in-from-bottom-8 fade-in duration-700">
          <div class="inline-flex items-center gap-2 bg-base-200/80 backdrop-blur-sm px-5 py-2 rounded-full border border-base-300 shadow-sm mb-6">
            <.icon name="hero-bolt-solid" class="size-4 text-primary" />
            <span class="text-[10px] font-black uppercase tracking-[0.3em] opacity-70">Plataforma Oficial</span>
          </div>

          <h1 class="text-7xl md:text-8xl font-black text-base-content tracking-tighter uppercase italic leading-[0.9]">
            Azar <span class="text-primary drop-shadow-md">UQ Pro</span>
          </h1>
          <p class="text-lg md:text-xl text-base-content/50 font-bold mt-6 tracking-widest uppercase text-xs md:text-sm max-w-xl mx-auto">
            Gestión inteligente y transparente de sorteos digitales
          </p>
        </div>

        <%!-- GRID DE OPCIONES --%>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8 px-4 sm:px-12 animate-in slide-in-from-bottom-12 fade-in duration-1000">

          <%!-- CARD ADMINISTRADOR --%>
          <.link
            navigate={~p"/admin/login"}
            class="group relative overflow-hidden p-10 bg-base-100/60 backdrop-blur-xl border border-base-200/50 rounded-[3rem] hover:border-primary/50 hover:shadow-2xl hover:shadow-primary/20 hover:-translate-y-3 transition-all duration-500"
          >
            <%!-- Efecto de brillo al hover --%>
            <div class="absolute inset-0 bg-gradient-to-br from-primary/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>

            <div class="relative z-10 flex flex-col items-center text-center space-y-6">
              <div class="p-6 bg-primary/10 text-primary rounded-[2rem] shadow-inner group-hover:bg-primary group-hover:text-white group-hover:rotate-12 group-hover:scale-110 transition-all duration-500">
                <.icon name="hero-cog-8-tooth-solid" class="size-12" />
              </div>

              <div>
                <h2 class="text-3xl font-black text-base-content uppercase tracking-tighter italic">Staff & Admin</h2>
                <p class="text-sm text-base-content/50 mt-4 leading-relaxed font-medium px-4">
                  Configura parámetros, controla el bombo digital y supervisa estadísticas.
                </p>
              </div>

              <div class="mt-4 pt-6 border-t border-base-300 w-full">
                <span class="inline-flex items-center gap-2 text-xs font-black uppercase tracking-widest text-primary group-hover:translate-x-2 transition-transform">
                  Acceso Restringido <.icon name="hero-arrow-right" class="size-4" />
                </span>
              </div>
            </div>
          </.link>

          <%!-- CARD CLIENTE --%>
          <.link
            navigate={~p"/login"}
            class="group relative overflow-hidden p-10 bg-base-100/60 backdrop-blur-xl border border-base-200/50 rounded-[3rem] hover:border-secondary/50 hover:shadow-2xl hover:shadow-secondary/20 hover:-translate-y-3 transition-all duration-500"
          >
             <%!-- Efecto de brillo al hover --%>
            <div class="absolute inset-0 bg-gradient-to-br from-secondary/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>

            <div class="relative z-10 flex flex-col items-center text-center space-y-6">
              <div class="p-6 bg-secondary/10 text-secondary rounded-[2rem] shadow-inner group-hover:bg-secondary group-hover:text-white group-hover:-rotate-12 group-hover:scale-110 transition-all duration-500">
                <.icon name="hero-ticket-solid" class="size-12" />
              </div>

              <div>
                <h2 class="text-3xl font-black text-base-content uppercase tracking-tighter italic">Portal Jugador</h2>
                <p class="text-sm text-base-content/50 mt-4 leading-relaxed font-medium px-4">
                  Compra fracciones, verifica resultados y cobra tus premios al instante.
                </p>
              </div>

              <div class="mt-4 pt-6 border-t border-base-300 w-full">
                <span class="inline-flex items-center gap-2 text-xs font-black uppercase tracking-widest text-secondary group-hover:translate-x-2 transition-transform">
                  Ingresar y Jugar <.icon name="hero-arrow-right" class="size-4" />
                </span>
              </div>
            </div>
          </.link>

        </div>

        <%!-- FOOTER DE CONFIANZA --%>
        <div class="pt-16 max-w-md mx-auto animate-in fade-in duration-1000 delay-300">
          <div class="flex flex-col items-center justify-center gap-3 text-base-content/40 bg-base-200/50 p-4 rounded-3xl border border-base-300/50">
             <.icon name="hero-shield-check-solid" class="size-6 text-base-content/30" />
             <span class="text-[10px] font-black uppercase tracking-[0.2em]">Arquitectura Segura • Elixir & Phoenix</span>
          </div>
        </div>

      </div>
    </div>
    """
  end
end
