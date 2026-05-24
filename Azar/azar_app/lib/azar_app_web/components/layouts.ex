defmodule AzarAppWeb.Layouts do
  @moduledoc false
  use AzarAppWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col relative" style="background:var(--bg-base)">

      <%!-- Luz ambiental sutil --%>
      <div class="pointer-events-none fixed inset-0 -z-10 overflow-hidden" aria-hidden="true">
        <div class="absolute -top-40 left-1/4 w-[500px] h-[500px] rounded-full"
          style="background:radial-gradient(circle,rgba(99,102,241,.08) 0%,transparent 70%)"></div>
        <div class="absolute bottom-0 right-0 w-[400px] h-[400px] rounded-full"
          style="background:radial-gradient(circle,rgba(245,158,11,.05) 0%,transparent 70%)"></div>
      </div>

      <%!-- NAVBAR --%>
      <header class="sticky top-0 z-50 w-full">
        <div class="absolute inset-0" style="background:rgba(15,15,23,.8);backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);border-bottom:1px solid var(--border)"></div>
        <div class="relative max-w-6xl mx-auto px-5 sm:px-8">
          <div class="flex items-center justify-between h-16">

            <%!-- Logo --%>
            <a href="/" class="group flex items-center gap-2.5 outline-none">
              <div class="w-8 h-8 rounded-xl flex items-center justify-center transition-transform duration-200 group-hover:scale-105"
                style="background:linear-gradient(135deg,#6366F1,#818CF8)">
                <.icon name="hero-sparkles-solid" class="size-4 text-white" />
              </div>
              <span class="font-display font-bold text-xl tracking-tight" style="color:var(--text-primary)">
                Azar<span style="color:var(--indigo)">.</span>
              </span>
            </a>

            <%!-- Nav central (desktop) --%>
            <nav class="hidden md:flex items-center gap-1">
              <a href="/cliente/sorteos"
                class="flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-medium transition-all duration-150"
                style="color:var(--text-secondary)"
                onmouseenter="this.style.color='var(--text-primary)';this.style.background='var(--bg-card)'"
                onmouseleave="this.style.color='var(--text-secondary)';this.style.background='transparent'">
                <.icon name="hero-ticket-solid" class="size-4" />
                Sorteos
              </a>
            </nav>

            <%!-- Derecha --%>
            <div class="flex items-center gap-3">
              <.theme_toggle />
              <div class="w-px h-5 hidden sm:block" style="background:var(--border)"></div>

              <%= if assigns[:current_user] || assigns[:current_usuario] do %>
                <div class="dropdown dropdown-end">
                  <div tabindex="0" role="button" class="flex items-center gap-2 cursor-pointer group">
                    <div class="w-8 h-8 rounded-xl flex items-center justify-center font-display font-bold text-sm transition-all duration-200"
                      style="background:var(--indigo-dim);color:var(--indigo-light)"
                      onmouseenter="this.style.background='var(--indigo)';this.style.color='white'"
                      onmouseleave="this.style.background='var(--indigo-dim)';this.style.color='var(--indigo-light)'">
                      U
                    </div>
                    <.icon name="hero-chevron-down-solid" class="size-3 hidden sm:block" style="color:var(--text-muted)" />
                  </div>
                  <ul tabindex="0" class="dropdown-content z-[1] mt-3 p-1.5 min-w-48 rounded-2xl shadow-2xl"
                    style="background:var(--bg-elevated);border:1px solid var(--border)">
                    <li>
                      <a href="/admin/sorteos"
                        class="flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-sm font-medium transition-all"
                        style="color:var(--text-secondary)"
                        onmouseenter="this.style.color='var(--text-primary)';this.style.background='var(--bg-card)'"
                        onmouseleave="this.style.color='var(--text-secondary)';this.style.background='transparent'">
                        <.icon name="hero-command-line-solid" class="size-4" style="color:var(--text-muted)" />
                        Panel Admin
                      </a>
                    </li>
                    <li class="my-1" style="border-top:1px solid var(--border)"></li>
                    <li>
                      <a href="/log_out"
                        class="flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-sm font-medium transition-all"
                        style="color:var(--rose)"
                        onmouseenter="this.style.background='var(--rose-dim)'"
                        onmouseleave="this.style.background='transparent'">
                        <.icon name="hero-arrow-right-on-rectangle-solid" class="size-4" />
                        Cerrar Sesión
                      </a>
                    </li>
                  </ul>
                </div>
              <% else %>
                <div class="flex items-center gap-2">
                  <a href="/login"
                    class="hidden sm:block px-4 py-2 rounded-xl text-sm font-medium transition-all duration-150"
                    style="color:var(--text-secondary)"
                    onmouseenter="this.style.color='var(--text-primary)'"
                    onmouseleave="this.style.color='var(--text-secondary)'">
                    Ingresar
                  </a>
                  <a href="/registro"
                    class="px-4 py-2 rounded-xl text-sm font-semibold transition-all duration-150 active:scale-95"
                    style="background:var(--indigo);color:white">
                    Crear cuenta
                  </a>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </header>

      <%!-- CONTENIDO --%>
      <main class="flex-grow py-8 w-full relative z-10">
        <div class="max-w-6xl mx-auto px-5 sm:px-8">
          <div class="relative z-50 mb-2">
            <.flash_group flash={@flash} />
          </div>
          {render_slot(@inner_block)}
        </div>
      </main>

      <%!-- FOOTER --%>
      <footer class="mt-auto py-10" style="border-top:1px solid var(--border)">
        <div class="max-w-6xl mx-auto px-5 sm:px-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div class="flex items-center gap-2">
            <div class="w-6 h-6 rounded-lg flex items-center justify-center"
              style="background:var(--indigo-dim)">
              <.icon name="hero-sparkles-solid" class="size-3" style="color:var(--indigo)" />
            </div>
            <span class="font-display font-bold tracking-tight" style="color:var(--text-muted)">
              Azar<span style="color:var(--indigo)">.</span>
            </span>
          </div>
          <p class="text-xs font-medium" style="color:var(--text-muted)">
            Plataforma de sorteos digitales · © <%= Date.utc_today().year %>
          </p>
        </div>
      </footer>
    </div>
    """
  end

  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite" class="flex flex-col gap-2">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
      <.flash kind={:warning} flash={@flash} />
      <.flash id="client-error" kind={:error} title={gettext("Sin conexión")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})} hidden>
        {gettext("Intentando reconectar")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
      <.flash id="server-error" kind={:error} title={gettext("Algo salió mal")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})} hidden>
        {gettext("Intentando reconectar")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex items-center rounded-lg p-0.5 gap-0.5" style="background:var(--bg-card)">
      <div class="absolute w-[calc(33.33%-2px)] h-[calc(100%-4px)] rounded-md
        left-[2px]
        [[data-theme=light]_&]:left-[calc(33.33%+1px)]
        [[data-theme=dark]_&]:left-[calc(66.66%+0px)]
        transition-all duration-200 ease-out"
        style="background:var(--bg-elevated);border:1px solid var(--border)">
      </div>
      <button class="relative z-10 flex items-center justify-center w-7 h-7 rounded-md transition-colors"
        style="color:var(--text-muted)"
        phx-click={JS.dispatch("phx:set-theme")} data-phx-theme="system" title="Sistema">
        <.icon name="hero-computer-desktop-solid" class="size-3.5" />
      </button>
      <button class="relative z-10 flex items-center justify-center w-7 h-7 rounded-md transition-colors"
        style="color:var(--text-muted)"
        phx-click={JS.dispatch("phx:set-theme")} data-phx-theme="light" title="Claro">
        <.icon name="hero-sun-solid" class="size-3.5" />
      </button>
      <button class="relative z-10 flex items-center justify-center w-7 h-7 rounded-md transition-colors"
        style="color:var(--text-muted)"
        phx-click={JS.dispatch("phx:set-theme")} data-phx-theme="dark" title="Oscuro">
        <.icon name="hero-moon-solid" class="size-3.5" />
      </button>
    </div>
    """
  end
end
