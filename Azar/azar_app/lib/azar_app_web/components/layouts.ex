defmodule AzarAppWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AzarAppWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col bg-base-100 selection:bg-primary selection:text-primary-content relative overflow-hidden">

      <%!-- LUCES AMBIENTALES GLOBALES --%>
      <div class="absolute top-0 w-full h-full overflow-hidden -z-10 pointer-events-none">
        <div class="absolute top-0 left-1/4 w-[500px] h-[500px] bg-primary/5 rounded-full blur-[150px]"></div>
        <div class="absolute top-1/3 right-1/4 w-[400px] h-[400px] bg-secondary/5 rounded-full blur-[150px]"></div>
      </div>

      <%!-- BARRA DE NAVEGACIÓN SUPERIOR (Sticky y Efecto Cristal Supremo) --%>
      <header class="sticky top-0 z-50 w-full backdrop-blur-2xl bg-base-100/60 border-b border-base-200/50 shadow-sm transition-all duration-500">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-20">

            <%!-- IZQUIERDA: Logo y Branding --%>
            <div class="flex-shrink-0 flex items-center gap-2 animate-in fade-in slide-in-from-left-4 duration-700">
              <a href="/" class="flex items-center gap-3 group outline-none">
                <div class="bg-primary/10 text-primary p-3 rounded-[1.5rem] group-hover:bg-primary group-hover:text-white group-hover:rotate-12 group-hover:scale-110 transition-all duration-500 shadow-inner">
                  <.icon name="hero-sparkles-solid" class="size-6" />
                </div>
                <div class="flex flex-col leading-none">
                  <span class="font-black text-2xl uppercase tracking-tighter italic text-base-content group-hover:text-primary transition-colors duration-500">
                    Azar<span class="text-primary drop-shadow-sm">App</span>
                  </span>
                  <span class="text-[8px] font-black uppercase tracking-[0.3em] opacity-40 ml-1">Portal Oficial</span>
                </div>
              </a>
            </div>

            <%!-- CENTRO: Enlaces de Navegación (Escritorio) --%>
            <nav class="hidden md:flex items-center space-x-2">
              <a href="/cliente/sorteos" class="px-5 py-2.5 rounded-2xl text-base-content/60 hover:text-primary hover:bg-primary/10 font-black text-[10px] uppercase tracking-widest transition-all flex items-center gap-2 group border border-transparent hover:border-primary/20">
                <.icon name="hero-ticket-solid" class="size-4 group-hover:scale-110 transition-transform" />
                Explorar Sorteos
              </a>
            </nav>

            <%!-- DERECHA: Acciones, Modo Oscuro y Usuario --%>
            <div class="flex items-center gap-2 sm:gap-6 animate-in fade-in slide-in-from-right-4 duration-700">

              <%!-- TU COMPONENTE DE TEMA ORIGINAL --%>
              <.theme_toggle />

              <%!-- Separador Visual --%>
              <div class="hidden sm:block h-8 w-px bg-base-300/50 rounded-full"></div>

              <%!-- MENÚ DE USUARIO --%>
              <%= if assigns[:current_user] || assigns[:current_usuario] do %>
                <div class="dropdown dropdown-end">
                  <div tabindex="0" role="button" class="btn btn-ghost h-auto py-2 px-3 rounded-[2rem] flex items-center gap-3 hover:bg-base-200/50 border border-transparent hover:border-base-300 transition-all group">
                    <div class="flex flex-col items-end leading-tight hidden sm:flex">
                      <span class="font-black text-xs uppercase tracking-tight text-base-content">Mi Cuenta</span>
                      <span class="text-[9px] font-bold text-success uppercase tracking-widest flex items-center gap-1">
                        <div class="size-1.5 bg-success rounded-full animate-pulse"></div> En línea
                      </span>
                    </div>
                    <div class="avatar placeholder">
                      <div class="bg-primary text-primary-content rounded-full w-10 shadow-lg shadow-primary/30 group-hover:scale-105 transition-transform">
                        <span class="text-sm font-black uppercase">U</span>
                      </div>
                    </div>
                  </div>

                  <ul tabindex="0" class="dropdown-content z-[1] menu p-3 shadow-2xl shadow-base-300/50 bg-base-100/90 backdrop-blur-xl rounded-[2.5rem] w-64 border border-base-200/50 mt-4">
                    <div class="px-4 pb-2 pt-1 border-b border-base-200/50 mb-2">
                       <span class="text-[10px] font-black uppercase tracking-widest text-base-content/40">Opciones de usuario</span>
                    </div>
                    <li>
                      <a href="/admin/sorteos" class="py-3 px-4 rounded-2xl hover:bg-base-200/50 font-bold text-sm flex items-center gap-3 group">
                        <div class="p-2 bg-secondary/10 text-secondary rounded-xl group-hover:bg-secondary group-hover:text-white transition-colors">
                          <.icon name="hero-command-line-solid" class="size-4" />
                        </div>
                        Panel Admin
                      </a>
                    </li>
                    <div class="divider my-0"></div>
                    <li>
                      <a href="/log_out" class="py-3 px-4 rounded-2xl text-error hover:bg-error/10 hover:text-error font-bold text-sm flex items-center gap-3 group">
                        <div class="p-2 bg-error/10 rounded-xl group-hover:bg-error group-hover:text-white transition-colors">
                          <.icon name="hero-arrow-right-on-rectangle-solid" class="size-4" />
                        </div>
                        Cerrar Sesión
                      </a>
                    </li>
                  </ul>
                </div>
              <% else %>
                <%!-- BOTONES PARA INVITADOS --%>
                <div class="hidden sm:flex items-center gap-3">
                  <a href="/login" class="btn btn-ghost rounded-[1.5rem] font-black text-xs uppercase tracking-widest text-base-content/60 hover:text-primary hover:bg-primary/10">
                    Ingresar
                  </a>
                  <a href="/registro" class="btn btn-primary rounded-[1.5rem] px-6 font-black text-xs uppercase tracking-widest text-white shadow-xl shadow-primary/30 hover:-translate-y-1 hover:shadow-primary/40 transition-all">
                    Crear Cuenta
                  </a>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </header>

      <%!-- CONTENEDOR PRINCIPAL --%>
      <main class="flex-grow pt-10 pb-24 w-full relative z-10">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <%!-- Notificaciones (Flash Messages) --%>
          <div class="relative z-50">
            <.flash_group flash={@flash} />
          </div>

          <%!-- El contenido de tus vistas (Sorteos, Cliente, etc.) --%>
          {render_slot(@inner_block)}
        </div>
      </main>

      <%!-- PIE DE PÁGINA (Footer) --%>
      <footer class="mt-auto relative z-10 border-t border-base-200/50 bg-base-100/50 backdrop-blur-md">
        <div class="max-w-7xl mx-auto px-4 py-12">
          <div class="flex flex-col items-center justify-center text-center space-y-4">
            <div class="flex items-center gap-2 opacity-50 grayscale hover:grayscale-0 transition-all duration-500 cursor-pointer group">
              <div class="bg-base-200 p-2 rounded-xl group-hover:bg-primary/10 transition-colors">
                <.icon name="hero-sparkles-solid" class="size-6 group-hover:text-primary transition-colors" />
              </div>
              <span class="font-black text-2xl tracking-tighter italic uppercase group-hover:text-primary transition-colors">Azar<span class="text-base-content/50 group-hover:text-primary">App</span></span>
            </div>
            <p class="font-bold text-[10px] text-base-content/40 uppercase tracking-widest max-w-sm">
              Plataforma segura y transparente de sorteos digitales.<br/>
              <span class="inline-block mt-2 px-3 py-1 bg-base-200 rounded-full">Copyright © <%= Date.utc_today().year %></span>
            </p>
          </div>
        </div>
      </footer>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite" class="flex flex-col gap-3">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center bg-base-200/50 backdrop-blur-sm rounded-[1.5rem] border border-base-300/50 overflow-hidden shadow-inner p-1">
      <div class="absolute w-[30%] h-[80%] rounded-xl bg-base-100 shadow-sm border border-base-200 left-[2%] [[data-theme=light]_&]:left-[35%] [[data-theme=dark]_&]:left-[68%] transition-all duration-300 ease-out" />

      <button
        class="flex justify-center items-center p-2 cursor-pointer w-10 h-8 relative z-10 text-base-content/50 hover:text-base-content transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-solid" class="size-4" />
      </button>

      <button
        class="flex justify-center items-center p-2 cursor-pointer w-10 h-8 relative z-10 text-base-content/50 hover:text-base-content transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-solid" class="size-4" />
      </button>

      <button
        class="flex justify-center items-center p-2 cursor-pointer w-10 h-8 relative z-10 text-base-content/50 hover:text-base-content transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-solid" class="size-4" />
      </button>
    </div>
    """
  end
end
