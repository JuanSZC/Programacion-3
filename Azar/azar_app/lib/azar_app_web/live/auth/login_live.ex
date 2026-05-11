defmodule AzarAppWeb.AuthLive.LoginLive do
  use AzarAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, error: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="py-12 flex flex-col items-center justify-center">
      <div class="w-full max-w-md relative">

        <%!-- Efecto de resplandor de fondo --%>
        <div class="absolute -inset-1 bg-gradient-to-r from-secondary/30 to-primary/30 rounded-[2.5rem] blur-lg opacity-50"></div>

        <%!-- Tarjeta Principal --%>
        <div class="relative bg-base-100/80 backdrop-blur-xl p-8 sm:p-12 rounded-[2rem] shadow-2xl border border-base-200">

          <%!-- Icono Superior --%>
          <div class="flex justify-center mb-6">
            <div class="p-4 bg-secondary text-secondary-content rounded-2xl shadow-lg shadow-secondary/30 -rotate-3 hover:rotate-0 transition-transform duration-300">
              <.icon name="hero-user-solid" class="size-8" />
            </div>
          </div>

          <%!-- Textos --%>
          <div class="text-center mb-8">
            <h1 class="text-3xl font-black text-base-content tracking-tight">Bienvenido de nuevo</h1>
            <p class="text-xs font-bold text-base-content/50 mt-2 uppercase tracking-widest">
              Ingresa a tu cuenta de Azar UQ
            </p>
          </div>

          <%!-- Mensajes de Error --%>
          <%= if Phoenix.Flash.get(@flash, :error) do %>
            <div class="flex items-start gap-3 bg-error/10 border border-error/20 text-error p-4 rounded-xl mb-6 shadow-sm" role="alert">
              <.icon name="hero-exclamation-triangle-solid" class="size-5 shrink-0 mt-0.5" />
              <p class="font-medium text-sm leading-tight"><%= Phoenix.Flash.get(@flash, :error) %></p>
            </div>
          <% end %>

          <%!-- Formulario --%>
          <.form action={~p"/sesion"} method="POST" for={%{}} class="space-y-5">
            <input type="hidden" name="tipo" value="cliente" />
            <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

            <div class="form-control w-full space-y-1">
              <label class="label p-0 pb-1">
                <span class="label-text font-bold text-base-content/80">Correo Electrónico</span>
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-base-content/40">
                  <.icon name="hero-envelope" class="size-5" />
                </div>
                <input type="email" name="email" required class="input input-bordered w-full pl-11 bg-base-200/50 focus:bg-base-100 focus:border-secondary transition-all rounded-xl font-medium" placeholder="ejemplo@correo.com" />
              </div>
            </div>

            <div class="form-control w-full space-y-1">
              <label class="label p-0 pb-1">
                <span class="label-text font-bold text-base-content/80">Contraseña</span>
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-base-content/40">
                  <.icon name="hero-key" class="size-5" />
                </div>
                <input type="password" name="password" required class="input input-bordered w-full pl-11 bg-base-200/50 focus:bg-base-100 focus:border-secondary transition-all rounded-xl font-medium tracking-widest" placeholder="••••••••" />
              </div>
            </div>

            <button type="submit" class="btn btn-secondary w-full rounded-xl text-lg font-bold shadow-lg shadow-secondary/30 hover:-translate-y-1 transition-all mt-4">
              Iniciar Sesión
            </button>
          </.form>

          <%!-- Footer de la tarjeta: Registro y Regreso --%>
          <div class="mt-8 text-center space-y-6">
            <p class="text-sm font-medium text-base-content/60">
              ¿No tienes cuenta?
              <.link navigate={~p"/registro"} class="text-secondary font-bold hover:text-secondary-focus hover:underline transition-colors ml-1">
                Regístrate aquí
              </.link>
            </p>

            <div class="pt-4 border-t border-base-200/50">
              <.link navigate={~p"/"} class="inline-flex items-center gap-2 text-sm font-semibold text-base-content/40 hover:text-secondary transition-colors group">
                <span class="group-hover:-translate-x-1 transition-transform">←</span> Volver al inicio
              </.link>
            </div>
          </div>

        </div> <%!-- Fin de Tarjeta Principal --%>
      </div>
    </div>
    """
  end
end
