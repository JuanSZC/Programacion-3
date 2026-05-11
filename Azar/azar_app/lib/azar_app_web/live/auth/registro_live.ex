defmodule AzarAppWeb.AuthLive.RegistroLive do
  use AzarAppWeb, :live_view
  alias AzarApp.Cuentas

  def mount(_params, _session, socket) do
    {:ok, assign(socket, error: nil, loading: false)}
  end

  def render(assigns) do
    ~H"""
    <div class="py-8 flex flex-col items-center justify-center">
      <div class="w-full max-w-lg relative">

        <%!-- Resplandor ambiental --%>
        <div class="absolute -inset-1 bg-gradient-to-tr from-secondary/20 via-primary/10 to-secondary/20 rounded-[2.5rem] blur-xl opacity-60"></div>

        <%!-- Tarjeta Cristal --%>
        <div class="relative bg-base-100/80 backdrop-blur-xl p-8 sm:p-10 rounded-[2.5rem] shadow-2xl border border-base-200">

          <%!-- Cabecera --%>
          <div class="text-center mb-8">
            <div class="inline-flex p-4 bg-secondary/10 text-secondary rounded-2xl mb-4">
              <.icon name="hero-user-plus-solid" class="size-8" />
            </div>
            <h1 class="text-3xl font-black text-base-content tracking-tight">Crea tu cuenta</h1>
            <p class="text-sm font-bold text-base-content/50 mt-2 uppercase tracking-widest">
              Únete a la comunidad Azar UQ
            </p>
          </div>

          <%!-- Errores --%>
          <%= if @error do %>
            <div class="flex items-center gap-3 bg-error/10 border border-error/20 text-error p-4 rounded-xl mb-6 shadow-sm">
              <.icon name="hero-x-circle-solid" class="size-5 shrink-0" />
              <p class="font-medium text-sm"><%= @error %></p>
            </div>
          <% end %>

          <form phx-submit="registrar" class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <%!-- Nombre --%>
              <div class="form-control w-full space-y-1">
                <label class="label p-0 pb-1">
                  <span class="label-text font-bold text-base-content/70">Nombre Completo</span>
                </label>
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-base-content/30">
                    <.icon name="hero-identification" class="size-5" />
                  </div>
                  <input type="text" name="nombre" required placeholder="Juan Pérez"
                    class="input input-bordered w-full pl-11 bg-base-200/50 focus:bg-base-100 focus:border-secondary rounded-xl transition-all" />
                </div>
              </div>

              <%!-- Cédula --%>
              <div class="form-control w-full space-y-1">
                <label class="label p-0 pb-1">
                  <span class="label-text font-bold text-base-content/70">Cédula</span>
                </label>
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-base-content/30">
                    <.icon name="hero-credit-card" class="size-5" />
                  </div>
                  <input type="text" name="cedula" required placeholder="123456..."
                    class="input input-bordered w-full pl-11 bg-base-200/50 focus:bg-base-100 focus:border-secondary rounded-xl transition-all" />
                </div>
              </div>
            </div>

            <%!-- Correo --%>
            <div class="form-control w-full space-y-1">
              <label class="label p-0 pb-1">
                <span class="label-text font-bold text-base-content/70">Correo Electrónico</span>
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-base-content/30">
                  <.icon name="hero-envelope" class="size-5" />
                </div>
                <input type="email" name="email" required placeholder="tu@correo.com"
                  class="input input-bordered w-full pl-11 bg-base-200/50 focus:bg-base-100 focus:border-secondary rounded-xl transition-all" />
              </div>
            </div>

            <%!-- Password --%>
            <div class="form-control w-full space-y-1">
              <label class="label p-0 pb-1">
                <span class="label-text font-bold text-base-content/70">Contraseña</span>
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-base-content/30">
                  <.icon name="hero-lock-closed" class="size-5" />
                </div>
                <input type="password" name="password" required minlength="6" placeholder="••••••••"
                  class="input input-bordered w-full pl-11 bg-base-200/50 focus:bg-base-100 focus:border-secondary rounded-xl transition-all tracking-widest" />
              </div>
            </div>

            <%!-- Botón Principal --%>
            <button type="submit" class="btn btn-secondary w-full rounded-xl text-lg font-bold shadow-lg shadow-secondary/30 hover:-translate-y-1 transition-all mt-6" disabled={@loading}>
              <%= if @loading do %>
                <span class="loading loading-spinner"></span> Creando tu espacio...
              <% else %>
                Crear mi cuenta
              <% end %>
            </button>
          </form>

          <%!-- Footer de la Tarjeta --%>
          <div class="mt-8 pt-6 border-t border-base-200 text-center space-y-4">
            <p class="text-sm font-medium text-base-content/60">
              ¿Ya eres parte de Azar?
              <.link navigate="/login" class="text-secondary font-bold hover:text-secondary-focus transition-colors ml-1 underline decoration-2 underline-offset-4">
                Inicia sesión aquí
              </.link>
            </p>

            <div class="block">
              <.link navigate={~p"/"} class="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-widest text-base-content/30 hover:text-secondary transition-colors group">
                <span class="group-hover:-translate-x-1 transition-transform">←</span> Inicio
              </.link>
            </div>
          </div>

        </div> <%!-- Fin de Tarjeta Cristal --%>
      </div>
    </div>
    """
  end

  def handle_event("registrar", params, socket) do
    socket = assign(socket, loading: true, error: nil)
    params_con_rol = Map.put(params, "rol", "cliente")

    case Cuentas.crear_usuario(params_con_rol) do
      {:ok, _usuario} ->
        {:noreply,
         socket
         |> put_flash(:info, "¡Bienvenido! Cuenta creada. Ahora puedes ingresar.")
         |> push_navigate(to: "/login")}

      {:error, _changeset} ->
        {:noreply, assign(socket, error: "El correo ya está en uso o los datos son inválidos.", loading: false)}
    end
  end
end
