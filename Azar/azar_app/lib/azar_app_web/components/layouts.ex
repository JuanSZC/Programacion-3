defmodule AzarAppWeb.Layouts do
  @moduledoc false
  use AzarAppWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  @doc """
  Layout principal para el área de clientes.
  """
  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col bg-base-100 relative">

      <%!-- Luz ambiental sutil — solo dos puntos, discretos --%>
      <div class="pointer-events-none fixed inset-0 -z-10 overflow-hidden" aria-hidden="true">
        <div class="absolute -top-32 left-1/3 w-[600px] h-[600px] bg-primary/8 rounded-full blur-[120px]"></div>
        <div class="absolute top-1/2 right-0 w-[400px] h-[400px] bg-secondary/6 rounded-full blur-[100px]"></div>
      </div>

      <%!-- NAVBAR --%>
      <header class="sticky top-0 z-50 w-full">
        <%!-- Línea de borde con blur real --%>
        <div class="absolute inset-0 bg-base-100/75 backdrop-blur-xl border-b border-base-content/8"></div>

        <div class="relative max-w-6xl mx-auto px-5 sm:px-8">
          <div class="flex items-center justify-between h-16">

            <%!-- Logo --%>
            <a href="/" class="group flex items-center gap-2.5 outline-none">
              <div class="w-8 h-8 bg-primary rounded-lg flex items-center justify-center shadow-sm group-hover:scale-105 transition-transform duration-200">
                <.icon name="hero-sparkles-solid" class="size-4 text-primary-content" />
              </div>
              <span class="font-display font-bold text-xl tracking-tight text-base-content group-hover:text-primary transition-colors duration-200">
                Azar<span class="text-primary">.</span>
              </span>
            </a>

            <%!-- Nav central (desktop) --%>
            <nav class="hidden md:flex items-center gap-1">
              <a
                href="/cliente/sorteos"
                class="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-base-content/60 hover:text-base-content hover:bg-base-content/5 transition-all duration-150"
              >
                <.icon name="hero-ticket-solid" class="size-4" />
                Sorteos
              </a>
            </nav>

            <%!-- Derecha: tema + usuario --%>
            <div class="flex items-center gap-3">

              <.theme_toggle />

              <div class="w-px h-5 bg-base-content/15 hidden sm:block"></div>

              <%= if assigns[:current_user] || assigns[:current_usuario] do %>
                <div class="dropdown dropdown-end">
                  <div
                    tabindex="0"
                    role="button"
                    class="flex items-center gap-2 cursor-pointer group"
                  >
                    <div class="w-8 h-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center font-display font-bold text-sm group-hover:bg-primary group-hover:text-primary-content transition-all duration-200">
                      U
                    </div>
                    <.icon name="hero-chevron-down-solid" class="size-3 text-base-content/40 group-hover:text-base-content/70 transition-colors hidden sm:block" />
                  </div>

                  <ul
                    tabindex="0"
                    class="dropdown-content z-[1] mt-3 p-1.5 min-w-48 bg-base-100 border border-base-content/10 rounded-xl shadow-xl shadow-base-content/5"
                  >
                    <li>
                      <a
                        href="/admin/sorteos"
                        class="flex items-center gap-2.5 px-3 py-2.5 rounded-lg text-sm font-medium text-base-content/70 hover:text-base-content hover:bg-base-content/5 transition-all"
                      >
                        <.icon name="hero-command-line-solid" class="size-4 text-base-content/40" />
                        Panel Admin
                      </a>
                    </li>
                    <li class="my-1 border-t border-base-content/8"></li>
                    <li>
                      <a
                        href="/log_out"
                        class="flex items-center gap-2.5 px-3 py-2.5 rounded-lg text-sm font-medium text-error/70 hover:text-error hover:bg-error/8 transition-all"
                      >
                        <.icon name="hero-arrow-right-on-rectangle-solid" class="size-4" />
                        Cerrar Sesión
                      </a>
                    </li>
                  </ul>
                </div>
              <% else %>
                <div class="flex items-center gap-2">
                  <a
                    href="/login"
                    class="hidden sm:block px-4 py-2 rounded-lg text-sm font-medium text-base-content/60 hover:text-base-content hover:bg-base-content/5 transition-all duration-150"
                  >
                    Ingresar
                  </a>
                  <a
                    href="/registro"
                    class="px-4 py-2 rounded-lg text-sm font-semibold bg-primary text-primary-content hover:opacity-90 active:scale-95 transition-all duration-150 shadow-sm shadow-primary/20"
                  >
                    Crear cuenta
                  </a>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </header>

      <%!-- CONTENIDO PRINCIPAL --%>
      <main class="flex-grow py-8 w-full relative z-10">
        <div class="max-w-6xl mx-auto px-5 sm:px-8">
          <div class="relative z-50 mb-2">
            <.flash_group flash={@flash} />
          </div>
          {render_slot(@inner_block)}
        </div>
      </main>

      <%!-- FOOTER --%>
      <footer class="mt-auto border-t border-base-content/8 py-10">
        <div class="max-w-6xl mx-auto px-5 sm:px-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div class="flex items-center gap-2">
            <div class="w-6 h-6 bg-primary/10 rounded-md flex items-center justify-center">
              <.icon name="hero-sparkles-solid" class="size-3 text-primary" />
            </div>
            <span class="font-display font-bold text-base-content/40 tracking-tight">
              Azar<span class="text-primary/60">.</span>
            </span>
          </div>
          <p class="text-xs text-base-content/35 font-medium">
            Plataforma de sorteos digitales · © <%= Date.utc_today().year %>
          </p>
        </div>
      </footer>
    </div>
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  @doc """
  Breve: flash_group.
  """
  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite" class="flex flex-col gap-2">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
      <.flash kind={:warning} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("Sin conexión")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Intentando reconectar")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Algo salió mal")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Intentando reconectar")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Toggle de tema: sistema / claro / oscuro.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex items-center bg-base-200/60 rounded-lg p-0.5 gap-0.5">
      <%!-- Indicador deslizante (CSS puro) --%>
      <div class="absolute w-[calc(33.33%-2px)] h-[calc(100%-4px)] rounded-md bg-base-100 shadow-sm border border-base-content/8
        left-[2px]
        [[data-theme=light]_&]:left-[calc(33.33%+1px)]
        [[data-theme=dark]_&]:left-[calc(66.66%+0px)]
        transition-all duration-200 ease-out">
      </div>

      <button
        class="relative z-10 flex items-center justify-center w-7 h-7 rounded-md text-base-content/50 hover:text-base-content transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        title="Sistema"
      >
        <.icon name="hero-computer-desktop-solid" class="size-3.5" />
      </button>

      <button
        class="relative z-10 flex items-center justify-center w-7 h-7 rounded-md text-base-content/50 hover:text-base-content transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        title="Claro"
      >
        <.icon name="hero-sun-solid" class="size-3.5" />
      </button>

      <button
        class="relative z-10 flex items-center justify-center w-7 h-7 rounded-md text-base-content/50 hover:text-base-content transition-colors"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        title="Oscuro"
      >
        <.icon name="hero-moon-solid" class="size-3.5" />
      </button>
    </div>
    """
  end
end
