defmodule AzarAppWeb.AuthLive.LoginLive do
  use AzarAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, error: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="py-12 flex flex-col items-center justify-center min-h-[85vh] animate-in fade-in zoom-in-95 duration-700">
      <div class="w-full max-w-md relative">

        <%!-- Efecto de resplandor de fondo animado --%>
        <div class="absolute -inset-4 bg-gradient-to-r from-secondary/40 via-primary/20 to-secondary/40 rounded-[4rem] blur-2xl opacity-40 animate-pulse pointer-events-none"></div>

        <%!-- Tarjeta Principal Premium --%>
        <div class="relative bg-base-100/90 backdrop-blur-3xl p-10 sm:p-14 rounded-[3rem] shadow-2xl border border-base-200/60 overflow-hidden group">

          <%!-- Brillo decorativo superior --%>
          <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-secondary/50 to-transparent opacity-50"></div>

          <%!-- Icono Superior --%>
          <div class="flex justify-center mb-8">
            <div class="p-5 bg-gradient-to-br from-secondary/20 to-secondary/5 border border-secondary/20 text-secondary rounded-[2rem] shadow-inner group-hover:scale-110 transition-transform duration-500">
              <.icon name="hero-user-solid" class="size-10" />
            </div>
          </div>

          <%!-- Textos --%>
          <div class="text-center mb-10 space-y-3">
            <h1 class="text-3xl md:text-4xl font-black italic uppercase tracking-tighter text-base-content drop-shadow-sm">
              Bienvenido <span class="text-secondary">de nuevo</span>
            </h1>
            <p class="text-[10px] font-black text-base-content/40 uppercase tracking-[0.3em]">
              Ingresa a tu cuenta de Azar UQ
            </p>
          </div>

          <%!-- Mensajes de Error --%>
          <%= if Phoenix.Flash.get(@flash, :error) do %>
            <div class="flex items-start gap-4 bg-error/10 border border-error/20 text-error p-5 rounded-2xl mb-8 shadow-sm animate-in slide-in-from-top-2" role="alert">
              <div class="p-1.5 bg-error/20 rounded-xl shrink-0">
                <.icon name="hero-exclamation-triangle-solid" class="size-5" />
              </div>
              <p class="font-bold text-[11px] uppercase tracking-wider leading-relaxed mt-1">
                <%= Phoenix.Flash.get(@flash, :error) %>
              </p>
            </div>
          <% end %>

          <%!-- Formulario --%>
          <.form action={~p"/sesion"} method="POST" for={%{}} class="space-y-6">
            <input type="hidden" name="tipo" value="cliente" />
            <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

            <div class="form-control w-full space-y-2">
              <label class="label p-0">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/60">Correo Electrónico</span>
              </label>
              <div class="relative group/input">
                <div class="absolute inset-y-0 left-0 pl-5 flex items-center pointer-events-none text-base-content/40 group-focus-within/input:text-secondary transition-colors">
                  <.icon name="hero-envelope-solid" class="size-5" />
                </div>
                <input type="email" name="email" required class="input input-bordered h-14 w-full pl-14 bg-base-200/50 focus:bg-base-100 focus:border-secondary focus:ring-4 focus:ring-secondary/10 transition-all rounded-2xl font-bold text-sm" placeholder="ejemplo@correo.com" />
              </div>
            </div>

            <div class="form-control w-full space-y-2">
              <label class="label p-0">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/60">Contraseña</span>
              </label>
              <div class="relative group/input">
                <div class="absolute inset-y-0 left-0 pl-5 flex items-center pointer-events-none text-base-content/40 group-focus-within/input:text-secondary transition-colors">
                  <.icon name="hero-key-solid" class="size-5" />
                </div>
                <input type="password" name="password" required class="input input-bordered h-14 w-full pl-14 bg-base-200/50 focus:bg-base-100 focus:border-secondary focus:ring-4 focus:ring-secondary/10 transition-all rounded-2xl font-black text-lg tracking-widest" placeholder="••••••••" />
              </div>
            </div>

            <button type="submit" class="btn btn-secondary h-14 w-full rounded-2xl shadow-xl shadow-secondary/30 hover:-translate-y-1 hover:shadow-secondary/40 transition-all mt-8 font-black text-[10px] uppercase tracking-[0.2em] gap-3">
              Iniciar Sesión
              <.icon name="hero-arrow-right-circle-solid" class="size-5" />
            </button>
          </.form>

          <%!-- Footer de la tarjeta: Registro y Regreso --%>
          <div class="mt-10 text-center space-y-8">
            <p class="text-[10px] font-black uppercase tracking-widest text-base-content/50 flex flex-col sm:flex-row items-center justify-center gap-2">
              ¿No tienes cuenta?
              <.link navigate={~p"/registro"} class="text-secondary hover:text-secondary-focus hover:underline decoration-2 underline-offset-4 transition-all">
                Regístrate aquí
              </.link>
            </p>

            <div class="pt-6 border-t border-base-200/50 flex justify-center">
              <.link navigate={~p"/"} class="inline-flex items-center gap-3 text-[10px] font-black uppercase tracking-widest text-base-content/40 hover:text-secondary transition-colors group/back">
                <div class="p-1.5 bg-base-200 rounded-lg group-hover/back:bg-secondary/10 transition-colors">
                  <.icon name="hero-arrow-left-solid" class="size-4 group-hover/back:-translate-x-1 transition-transform" />
                </div>
                Volver al inicio
              </.link>
            </div>
          </div>

        </div> <%!-- Fin de Tarjeta Principal --%>
      </div>
    </div>
    """
  end
end
