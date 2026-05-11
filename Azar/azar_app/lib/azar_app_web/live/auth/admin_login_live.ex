defmodule AzarAppWeb.AuthLive.AdminLoginLive do
  use AzarAppWeb, :live_view

  def mount(_params, _session, socket) do
    # Iniciamos con error nil; si el controlador nos rebota, lo hará vía Flash
    {:ok, assign(socket, error: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="py-12 flex flex-col items-center justify-center">
      <div class="w-full max-w-md relative">

        <%!-- Efecto de resplandor de fondo (Ambient Glow) --%>
        <div class="absolute -inset-1 bg-gradient-to-r from-primary/30 to-secondary/30 rounded-[2.5rem] blur-lg opacity-50"></div>

        <%!-- Tarjeta Principal con efecto cristal --%>
        <div class="relative bg-base-100/80 backdrop-blur-xl p-8 sm:p-12 rounded-[2rem] shadow-2xl border border-base-200">

          <%!-- Icono Superior --%>
          <div class="flex justify-center mb-6">
            <div class="p-4 bg-primary text-primary-content rounded-2xl shadow-lg shadow-primary/30 rotate-3 hover:rotate-0 transition-transform duration-300">
              <.icon name="hero-lock-closed-solid" class="size-8" />
            </div>
          </div>

          <%!-- Textos --%>
          <div class="text-center mb-8">
            <h1 class="text-3xl font-black text-base-content tracking-tight">Acceso Admin</h1>
            <p class="text-xs font-bold text-base-content/50 mt-2 uppercase tracking-widest">
              Solo Personal Autorizado
            </p>
          </div>

          <%!-- Mensajes de Error (Flash) modernizados --%>
          <%= if Phoenix.Flash.get(@flash, :error) do %>
            <div class="flex items-start gap-3 bg-error/10 border border-error/20 text-error p-4 rounded-xl mb-6 shadow-sm" role="alert">
              <.icon name="hero-exclamation-triangle-solid" class="size-5 shrink-0 mt-0.5" />
              <p class="font-medium text-sm leading-tight"><%= Phoenix.Flash.get(@flash, :error) %></p>
            </div>
          <% end %>

          <%!-- El action apunta a /sesion (POST) manejado por SesionController --%>
          <.form action={~p"/sesion"} method="POST" for={%{}} class="space-y-5">

            <%!-- Campos Ocultos --%>
            <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
            <input type="hidden" name="tipo" value="admin" />

            <%!-- Input Correo --%>
            <div class="form-control w-full space-y-1">
              <label class="label p-0 pb-1">
                <span class="label-text font-bold text-base-content/80">Credencial (Correo)</span>
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-base-content/40">
                  <.icon name="hero-envelope" class="size-5" />
                </div>
                <input
                  type="email"
                  name="email"
                  required
                  class="input input-bordered w-full pl-11 bg-base-200/50 focus:bg-base-100 focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all rounded-xl font-medium"
                  placeholder="admin@azar.com"
                />
              </div>
            </div>

            <%!-- Input Contraseña --%>
            <div class="form-control w-full space-y-1">
              <label class="label p-0 pb-1">
                <span class="label-text font-bold text-base-content/80">Clave de Acceso</span>
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-base-content/40">
                  <.icon name="hero-key" class="size-5" />
                </div>
                <input
                  type="password"
                  name="password"
                  required
                  class="input input-bordered w-full pl-11 bg-base-200/50 focus:bg-base-100 focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all rounded-xl font-medium tracking-widest"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <%!-- Botón Submit --%>
            <button type="submit" class="btn btn-primary w-full rounded-xl text-lg font-bold shadow-lg shadow-primary/30 hover:-translate-y-1 transition-all mt-4">
              Ingresar al Sistema
            </button>
          </.form>

          <%!-- Enlace de regreso --%>
          <div class="mt-8 text-center">
            <.link navigate={~p"/"} class="inline-flex items-center gap-2 text-sm font-semibold text-base-content/50 hover:text-primary transition-colors group">
              <span class="group-hover:-translate-x-1 transition-transform">←</span> Volver al inicio
            </.link>
          </div>
        </div>

      </div>
    </div>
    """
  end
end
