defmodule AzarAppWeb.Layouts do
  @moduledoc false
  use AzarAppWeb, :html

  embed_templates("layouts/*")

  attr(:flash, :map, required: true)
  attr(:current_scope, :map, default: nil)
  slot(:inner_block, required: true)

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
        <div class="absolute inset-0" style="background:var(--header-bg);backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);border-bottom:1px solid var(--border)"></div>
        <div class="relative max-w-6xl mx-auto px-5 sm:px-8">
          <div class="flex items-center justify-between h-16">

            <%!-- Logo --%>
            <a href="/" class="group flex items-center gap-2.5 outline-none">
              <div class="w-8 h-8 rounded-xl flex items-center justify-center transition-transform duration-200 group-hover:scale-105"
                style="background:linear-gradient(135deg,var(--menu-primary),var(--menu-primary-light))">
                <.icon name="hero-sparkles-solid" class="size-4 text-white" />
              </div>
              <span class="font-display font-bold text-xl tracking-tight" style="color:var(--text-primary)">
                Azar<span style="color:var(--menu-primary)">.</span>
              </span>
            </a>

            <%!-- Nav central (desktop) --%>
            <nav class="hidden md:flex items-center gap-1">
              <a href="/cliente/sorteos"
                class="flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-medium transition-all duration-150"
                style="color:var(--menu-primary)"
                onmouseenter="this.style.color='var(--text-primary)';this.style.background='var(--bg-card)'"
                onmouseleave="this.style.color='var(--menu-primary)';this.style.background='transparent'">
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
                      style="background:var(--menu-primary-dim);color:var(--menu-primary)"
                      onmouseenter="this.style.background='var(--menu-primary)';this.style.color='white'"
                      onmouseleave="this.style.background='var(--menu-primary-dim)';this.style.color='var(--menu-primary)'">
                      U
                    </div>
    <.icon name="hero-chevron-down-solid" class="size-3 hidden sm:block text-[var(--text-muted)]" />                  </div>
                  <ul tabindex="0" class="dropdown-content z-[1] mt-3 p-1.5 min-w-48 rounded-2xl shadow-2xl"
                    style="background:var(--bg-elevated);border:1px solid var(--border)">
                    <li>
                      <a href="/admin/sorteos"
                        class="flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-sm font-medium transition-all"
                        style="color:var(--text-secondary)"
                        onmouseenter="this.style.color='var(--text-primary)';this.style.background='var(--bg-card)'"
                        onmouseleave="this.style.color='var(--text-secondary)';this.style.background='transparent'">
    <.icon name="hero-command-line-solid" class="size-4 text-[var(--text-muted)]" />                        Panel Admin
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
                    style="color:var(--menu-primary)"
                    onmouseenter="this.style.color='var(--text-primary)'"
                    onmouseleave="this.style.color='var(--menu-primary)'">
                    Ingresar
                  </a>
                  <a href="/registro"
                    class="px-4 py-2 rounded-xl text-sm font-semibold transition-all duration-150 active:scale-95"
                    style="background:var(--menu-primary);color:white">
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
    <.icon name="hero-sparkles-solid" class="size-3 text-[var(--indigo)]" />
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

  attr(:flash, :map, required: true)
  attr(:id, :string, default: "flash-group")

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
  <div id="theme-switch" style="
    width:96px;height:36px;
    border-radius:999px;
    background:var(--color-base-200);
    border:1px solid var(--color-base-300);
    position:relative;
    display:flex;align-items:center;
    padding:3px;
    box-sizing:border-box;
  ">
    <div id="theme-knob" style="
      width:28px;height:28px;
      border-radius:50%;
      background:var(--color-base-100);
      border:1px solid var(--color-base-300);
      position:absolute;left:3px;
      transition:left 0.25s cubic-bezier(.4,0,.2,1);
      box-shadow:0 1px 3px rgba(0,0,0,.15);
      pointer-events:none;
    "></div>

    <button onclick="window.setTheme('system')" title="Sistema" id="btn-system" style="
      position:absolute;left:3px;width:28px;height:28px;
      border:none;background:transparent;cursor:pointer;
      border-radius:50%;display:flex;align-items:center;justify-content:center;
      transition:opacity 0.2s;z-index:1;
    ">
      <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24"
        fill="none" stroke="#7C6AF7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/>
      </svg>
    </button>

    <button onclick="window.setTheme('light')" title="Claro" id="btn-light" style="
      position:absolute;left:35px;width:28px;height:28px;
      border:none;background:transparent;cursor:pointer;
      border-radius:50%;display:flex;align-items:center;justify-content:center;
      transition:opacity 0.2s;opacity:0.25;z-index:1;
    ">
      <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24"
        fill="none" stroke="#F59E0B" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"/>
      </svg>
    </button>

    <button onclick="window.setTheme('dark')" title="Oscuro" id="btn-dark" style="
      position:absolute;left:65px;width:28px;height:28px;
      border:none;background:transparent;cursor:pointer;
      border-radius:50%;display:flex;align-items:center;justify-content:center;
      transition:opacity 0.2s;opacity:0.25;z-index:1;
    ">
      <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24"
        fill="none" stroke="#60A5FA" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9z"/>
        <path d="M19 3v4M21 5h-4"/>
      </svg>
    </button>
  </div>

  <script>
    window.setTheme = function(theme) {
      const root = document.documentElement;
      const resolved = theme === 'system'
        ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
        : theme;

      root.setAttribute('data-theme', resolved);
      localStorage.setItem('app-theme', theme);

      const positions = { system: '3px', light: '35px', dark: '65px' };
      const knob = document.getElementById('theme-knob');
      if (knob) knob.style.left = positions[theme];

      ['system', 'light', 'dark'].forEach(function(t) {
        const btn = document.getElementById('btn-' + t);
        if (btn) btn.style.opacity = t === theme ? '1' : '0.25';
      });
    };

    (function() {
      const saved = localStorage.getItem('app-theme') || 'system';
      window.setTheme(saved);
    })();
  </script>
  """
end
end
