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
    <div class="min-h-screen flex flex-col">
      <%!-- BARRA DE NAVEGACIÓN SUPERIOR (Sticky y Efecto Cristal) --%>
      <header class="sticky top-0 z-50 w-full backdrop-blur-xl bg-base-100/80 border-b border-base-200 shadow-sm transition-colors duration-300">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-16 sm:h-20">

            <%!-- IZQUIERDA: Logo y Branding --%>
            <div class="flex-shrink-0 flex items-center gap-2">
              <a href="/" class="flex items-center gap-2 group outline-none">
                <div class="bg-primary text-primary-content p-2.5 rounded-2xl group-hover:rotate-12 group-hover:scale-110 transition-all shadow-lg shadow-primary/30">
                  <.icon name="hero-sparkles-solid" class="size-6" />
                </div>
                <span class="font-extrabold text-2xl tracking-tight text-base-content group-hover:text-primary transition-colors">
                  Azar<span class="text-primary">App</span>
                </span>
              </a>
            </div>

            <%!-- CENTRO: Enlaces de Navegación (Escritorio) --%>
            <nav class="hidden md:flex items-center space-x-1">
              <a href="/cliente/sorteos" class="px-4 py-2 rounded-xl text-base-content/70 hover:text-primary hover:bg-primary/10 font-bold transition-all flex items-center gap-2">
                <.icon name="hero-ticket" class="size-5" />
                Explorar Sorteos
              </a>
            </nav>

            <%!-- DERECHA: Acciones, Modo Oscuro y Usuario --%>
            <div class="flex items-center gap-2 sm:gap-4">

              <%!-- TU COMPONENTE DE TEMA ORIGINAL (Integrado a la perfección) --%>
              <.theme_toggle />

              <%!-- Separador Visual --%>
              <div class="hidden sm:block h-8 w-px bg-base-200 mx-1"></div>

              <%!-- MENÚ DE USUARIO (Mockup dinámico) --%>
              <%= if assigns[:current_user] || assigns[:current_usuario] do %>
                <div class="dropdown dropdown-end">
                  <div tabindex="0" role="button" class="btn btn-ghost rounded-2xl px-2 py-1 flex items-center gap-3 hover:bg-base-200 border border-transparent hover:border-base-300 transition-all">
                    <div class="avatar placeholder">
                      <div class="bg-primary text-primary-content rounded-xl w-9 shadow-md">
                        <span class="text-sm font-black uppercase">U</span>
                      </div>
                    </div>
                    <div class="hidden sm:flex flex-col items-start leading-tight">
                      <span class="font-bold text-sm text-base-content">Mi Cuenta</span>
                      <span class="text-[10px] font-semibold text-primary uppercase tracking-wider">Online</span>
                    </div>
                    <.icon name="hero-chevron-down" class="size-4 opacity-50 hidden sm:block" />
                  </div>

                  <ul tabindex="0" class="dropdown-content z-[1] menu p-2 shadow-2xl shadow-base-300/50 bg-base-100 rounded-3xl w-56 border border-base-200 mt-4 font-medium">
                    <li>
                      <a href="/admin/sorteos" class="py-3 rounded-xl hover:bg-base-200">
                        <.icon name="hero-command-line" class="size-5 text-secondary" />
                        Panel Admin
                      </a>
                    </li>
                    <div class="divider my-1"></div>
                    <li>
                      <a href="/log_out" class="py-3 rounded-xl text-error hover:bg-error/10 hover:text-error">
                        <.icon name="hero-arrow-right-on-rectangle" class="size-5" />
                        Cerrar Sesión
                      </a>
                    </li>
                  </ul>
                </div>
              <% else %>
                <%!-- BOTONES PARA INVITADOS --%>
                <div class="hidden sm:flex items-center gap-3">
                  <a href="/login" class="btn btn-ghost rounded-xl font-bold text-base-content/70 hover:text-primary hover:bg-primary/10">
                    Ingresar
                  </a>
                  <a href="/registro" class="btn btn-primary rounded-xl px-6 shadow-lg shadow-primary/30 hover:-translate-y-0.5 transition-transform font-bold">
                    Crear Cuenta
                  </a>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </header>

      <%!-- CONTENEDOR PRINCIPAL DONDE SE CARGAN TUS PÁGINAS --%>
      <main class="flex-grow pt-8 pb-20 w-full">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <%!-- Notificaciones (Flash Messages) --%>
          <.flash_group flash={@flash} />

          <%!-- El contenido de tus vistas (Sorteos, Admin, etc.) --%>
          {render_slot(@inner_block)}
        </div>
      </main>

      <%!-- PIE DE PÁGINA (Footer) --%>
      <footer class="footer footer-center p-10 bg-base-200/50 text-base-content rounded-t-3xl border-t border-base-200 mt-auto">
        <aside>
          <div class="flex items-center justify-center gap-2 mb-3 opacity-60 grayscale hover:grayscale-0 transition-all cursor-pointer">
            <.icon name="hero-sparkles-solid" class="size-8" />
            <span class="font-extrabold text-2xl tracking-tight">AzarApp</span>
          </div>
          <p class="font-medium text-sm text-base-content/70">
            Plataforma segura de sorteos digitales. <br/>
            Copyright © <%= Date.utc_today().year %> - Todos los derechos reservados.
          </p>
        </aside>
      </footer>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
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

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
