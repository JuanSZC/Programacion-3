defmodule AzarAppWeb.AuthLive.AdminLoginLive do
  use AzarAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, error: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="relative flex flex-col items-center justify-center min-h-screen bg-base-100 overflow-hidden">
      <%!-- LUCES DE FONDO --%>
      <div class="absolute top-0 left-0 w-full h-full overflow-hidden -z-10 pointer-events-none">
        <div class="absolute -top-32 -right-32 w-[500px] h-[500px] bg-primary/10 rounded-full blur-[120px] animate-pulse"></div>
        <div class="absolute -bottom-40 -left-20 w-[400px] h-[400px] bg-primary/5 rounded-full blur-[100px] animate-pulse" style="animation-delay: 1.5s;"></div>
      </div>

      <div class="w-full max-w-md relative z-10 px-4 animate-in fade-in zoom-in-95 duration-700">
        <div class="relative bg-base-100/70 backdrop-blur-2xl p-8 sm:p-12 rounded-[3rem] shadow-2xl border border-base-200/50">

          <div class="flex justify-center mb-8">
            <div class="p-5 bg-primary/10 text-primary rounded-[2rem] shadow-inner rotate-3 hover:rotate-0 hover:scale-110 hover:bg-primary hover:text-white transition-all duration-500">
              <.icon name="hero-shield-check-solid" class="size-10" />
            </div>
          </div>

          <div class="text-center mb-10">
            <h1 class="text-4xl font-black text-base-content tracking-tighter uppercase italic">
              Acceso <span class="text-primary">Admin</span>
            </h1>
            <p class="text-[10px] font-black text-base-content/40 mt-3 uppercase tracking-[0.3em]">
              <span class="inline-block w-2 h-2 bg-error rounded-full animate-pulse mr-1"></span>
              Área Restringida
            </p>
          </div>

          <%= if Phoenix.Flash.get(@flash, :error) do %>
            <div class="flex items-center gap-3 bg-error/10 border border-error/20 text-error p-4 rounded-2xl mb-8 shadow-sm animate-in slide-in-from-top-2" role="alert">
              <.icon name="hero-exclamation-triangle-solid" class="size-5 shrink-0" />
              <p class="font-bold text-xs uppercase tracking-widest"><%= Phoenix.Flash.get(@flash, :error) %></p>
            </div>
          <% end %>

          <%!-- FORMULARIO POST HACIA EL CONTROLADOR --%>
          <.form action={~p"/sesion"} method="POST" for={%{}} class="space-y-6">
            <%!-- TOKEN CSRF CORREGIDO --%>
            <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
            <input type="hidden" name="tipo" value="admin" />

            <div class="form-control w-full space-y-2">
              <label class="label p-0 ml-2">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/50">Credencial (Correo)</span>
              </label>
              <div class="relative group">
                <div class="absolute inset-y-0 left-0 pl-5 flex items-center pointer-events-none text-base-content/30 group-focus-within:text-primary transition-colors">
                  <.icon name="hero-envelope-solid" class="size-5" />
                </div>
                <input
                  type="email"
                  name="email"
                  required
                  class="input input-bordered w-full h-14 pl-14 bg-base-200/50 border-none focus:bg-base-100 focus:ring-2 focus:ring-primary/50 transition-all rounded-2xl font-bold text-base-content shadow-inner"
                  placeholder="admin@azar.com"
                />
              </div>
            </div>

            <div class="form-control w-full space-y-2">
              <label class="label p-0 ml-2">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/50">Clave de Acceso</span>
              </label>
              <div class="relative group">
                <div class="absolute inset-y-0 left-0 pl-5 flex items-center pointer-events-none text-base-content/30 group-focus-within:text-primary transition-colors">
                  <.icon name="hero-key-solid" class="size-5" />
                </div>
                <input
                  type="password"
                  name="password"
                  required
                  class="input input-bordered w-full h-14 pl-14 bg-base-200/50 border-none focus:bg-base-100 focus:ring-2 focus:ring-primary/50 transition-all rounded-2xl font-black tracking-[0.3em] text-lg text-base-content shadow-inner"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <div class="pt-4">
              <button type="submit" class="btn btn-primary w-full h-14 rounded-2xl text-sm font-black uppercase tracking-widest text-white shadow-xl shadow-primary/30 hover:-translate-y-1 hover:shadow-primary/40 transition-all group">
                Ingresar al Sistema
                <.icon name="hero-arrow-right" class="size-5 ml-2 opacity-50 group-hover:opacity-100 group-hover:translate-x-1 transition-all" />
              </button>
            </div>
          </.form>
        </div>

        <div class="mt-8 text-center">
          <.link navigate={~p"/"} class="inline-flex items-center justify-center gap-2 text-[10px] font-black uppercase tracking-[0.2em] text-base-content/40 hover:text-primary transition-colors group p-2">
            <span class="group-hover:-translate-x-1 transition-transform"><.icon name="hero-arrow-left" class="size-4" /></span>
            Volver al portal principal
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
