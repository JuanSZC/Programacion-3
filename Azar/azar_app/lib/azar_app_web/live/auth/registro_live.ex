defmodule AzarAppWeb.AuthLive.RegistroLive do
  use AzarAppWeb, :live_view
  alias AzarApp.Cuentas

  def mount(_params, _session, socket) do
    {:ok, assign(socket, error: nil, loading: false)}
  end

  def render(assigns) do
    ~H"""
    <div class="py-12 flex flex-col items-center justify-center min-h-[85vh] animate-in fade-in zoom-in-95 duration-700">
      <div class="w-full max-w-lg relative">

        <%!-- Resplandor ambiental animado --%>
        <div class="absolute -inset-4 bg-gradient-to-tr from-secondary/40 via-primary/20 to-secondary/40 rounded-[4rem] blur-2xl opacity-40 animate-pulse pointer-events-none"></div>

        <%!-- Tarjeta Cristal Premium --%>
        <div class="relative bg-base-100/90 backdrop-blur-3xl p-10 sm:p-14 rounded-[3rem] shadow-2xl border border-base-200/60 overflow-hidden group">

          <%!-- Brillo decorativo superior --%>
          <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-secondary/50 to-transparent opacity-50"></div>

          <%!-- Cabecera --%>
          <div class="flex justify-center mb-8">
            <div class="p-5 bg-gradient-to-br from-secondary/20 to-secondary/5 border border-secondary/20 text-secondary rounded-[2rem] shadow-inner group-hover:scale-110 transition-transform duration-500">
              <.icon name="hero-user-plus-solid" class="size-10" />
            </div>
          </div>

          <div class="text-center mb-10 space-y-3">
            <h1 class="text-3xl md:text-4xl font-black italic uppercase tracking-tighter text-base-content drop-shadow-sm">
              Crea tu <span class="text-secondary">cuenta</span>
            </h1>
            <p class="text-[10px] font-black text-base-content/40 uppercase tracking-[0.3em]">
              Únete a la comunidad Azar UQ
            </p>
          </div>

          <%!-- Errores --%>
          <%= if @error do %>
            <div class="flex items-start gap-4 bg-error/10 border border-error/20 text-error p-5 rounded-2xl mb-8 shadow-sm animate-in slide-in-from-top-2" role="alert">
              <div class="p-1.5 bg-error/20 rounded-xl shrink-0">
                <.icon name="hero-x-circle-solid" class="size-5" />
              </div>
              <p class="font-bold text-[11px] uppercase tracking-wider leading-relaxed mt-1">
                <%= @error %>
              </p>
            </div>
          <% end %>

          <form phx-submit="registrar" class="space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-5 md:gap-6">

              <%!-- Nombre --%>
              <div class="form-control w-full space-y-2">
                <label class="label p-0">
                  <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/60">Nombre Completo</span>
                </label>
                <div class="relative group/input">
                  <div class="absolute inset-y-0 left-0 pl-5 flex items-center pointer-events-none text-base-content/40 group-focus-within/input:text-secondary transition-colors">
                    <.icon name="hero-identification-solid" class="size-5" />
                  </div>
                  <input type="text" name="nombre" required placeholder="Juan Pérez"
                    class="input input-bordered h-14 w-full pl-14 bg-base-200/50 focus:bg-base-100 focus:border-secondary focus:ring-4 focus:ring-secondary/10 transition-all rounded-2xl font-bold text-sm" />
                </div>
              </div>

              <%!-- Cédula --%>
              <div class="form-control w-full space-y-2">
                <label class="label p-0">
                  <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/60">Cédula</span>
                </label>
                <div class="relative group/input">
                  <div class="absolute inset-y-0 left-0 pl-5 flex items-center pointer-events-none text-base-content/40 group-focus-within/input:text-secondary transition-colors">
                    <.icon name="hero-credit-card-solid" class="size-5" />
                  </div>
                  <input type="text" name="cedula" required placeholder="123456..."
                    class="input input-bordered h-14 w-full pl-14 bg-base-200/50 focus:bg-base-100 focus:border-secondary focus:ring-4 focus:ring-secondary/10 transition-all rounded-2xl font-bold text-sm" />
                </div>
              </div>
            </div>

            <%!-- Correo --%>
            <div class="form-control w-full space-y-2">
              <label class="label p-0">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/60">Correo Electrónico</span>
              </label>
              <div class="relative group/input">
                <div class="absolute inset-y-0 left-0 pl-5 flex items-center pointer-events-none text-base-content/40 group-focus-within/input:text-secondary transition-colors">
                  <.icon name="hero-envelope-solid" class="size-5" />
                </div>
                <input type="email" name="email" required placeholder="tu@correo.com"
                  class="input input-bordered h-14 w-full pl-14 bg-base-200/50 focus:bg-base-100 focus:border-secondary focus:ring-4 focus:ring-secondary/10 transition-all rounded-2xl font-bold text-sm" />
              </div>
            </div>

            <%!-- Password --%>
            <div class="form-control w-full space-y-2">
              <label class="label p-0">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/60">Contraseña</span>
              </label>
              <div class="relative group/input">
                <div class="absolute inset-y-0 left-0 pl-5 flex items-center pointer-events-none text-base-content/40 group-focus-within/input:text-secondary transition-colors">
                  <.icon name="hero-lock-closed-solid" class="size-5" />
                </div>
                <input type="password" name="password" required minlength="6" placeholder="••••••••"
                  class="input input-bordered h-14 w-full pl-14 bg-base-200/50 focus:bg-base-100 focus:border-secondary focus:ring-4 focus:ring-secondary/10 transition-all rounded-2xl font-black text-lg tracking-widest" />
              </div>
            </div>

            <%!-- Botón Principal --%>
            <button type="submit" disabled={@loading} class={[
              "btn btn-secondary h-14 w-full rounded-2xl shadow-xl transition-all mt-8 font-black text-[10px] uppercase tracking-[0.2em] gap-3",
              if(@loading, do: "opacity-70 cursor-wait", else: "shadow-secondary/30 hover:-translate-y-1 hover:shadow-secondary/40")
            ]}>
              <%= if @loading do %>
                <span class="loading loading-spinner loading-md"></span> Creando tu espacio...
              <% else %>
                Crear mi cuenta
                <.icon name="hero-check-circle-solid" class="size-5" />
              <% end %>
            </button>
          </form>

          <%!-- Footer de la Tarjeta --%>
          <div class="mt-10 text-center space-y-8">
            <p class="text-[10px] font-black uppercase tracking-widest text-base-content/50 flex flex-col sm:flex-row items-center justify-center gap-2">
              ¿Ya eres parte de Azar?
              <.link navigate="/login" class="text-secondary hover:text-secondary-focus hover:underline decoration-2 underline-offset-4 transition-all">
                Inicia sesión aquí
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
