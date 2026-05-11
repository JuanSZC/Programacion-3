defmodule AzarAppWeb.Cliente.PerfilLive do
  use AzarAppWeb, :live_view
  alias AzarApp.Cuentas

  def mount(_params, session, socket) do
    usuario_id = session["usuario_id"]

    if usuario_id do
      usuario = Cuentas.obtener_usuario!(usuario_id)
      {:ok,
       socket
       |> assign(usuario: usuario)
       |> assign(show_modal: false)
       |> assign(seccion_activa: "info")
       |> assign(editando_campo: nil)}
    else
      {:ok, push_navigate(socket, to: "/login")}
    end
  end

  # --- EVENTOS DE NAVEGACIÓN Y UI ---
  def handle_event("set_seccion", %{"sec" => sec}, socket), do: {:noreply, assign(socket, seccion_activa: sec, editando_campo: nil)}
  def handle_event("editar", %{"campo" => campo}, socket), do: {:noreply, assign(socket, editando_campo: campo)}
  def handle_event("cancelar_edicion", _, socket), do: {:noreply, assign(socket, editando_campo: nil)}

  # --- EVENTOS DE ACTUALIZACIÓN ---
  def handle_event("guardar_cambios", %{"campo" => campo, "valor" => valor}, socket) do
    case Cuentas.actualizar_campo_usuario(socket.assigns.usuario, campo, valor) do
      {:ok, usuario_actualizado} ->
        {:noreply,
         socket
         |> assign(usuario: usuario_actualizado, editando_campo: nil)
         |> put_flash(:info, "¡#{String.capitalize(campo)} actualizado!")}
      {:error, _mensaje} ->
        {:noreply, put_flash(socket, :error, "Error al actualizar")}
    end
  end

  # --- EVENTOS DE RECARGA ---
  def handle_event("abrir_modal", _, socket), do: {:noreply, assign(socket, show_modal: true)}
  def handle_event("cerrar_modal", _, socket), do: {:noreply, assign(socket, show_modal: false)}

  def handle_event("confirmar_recarga", %{"monto" => monto}, socket) do
    monto_int = String.to_integer(monto)
    case Cuentas.recargar_saldo(socket.assigns.usuario, monto_int) do
      {:ok, usuario_actualizado} ->
        {:noreply,
         socket
         |> assign(usuario: usuario_actualizado, show_modal: false)
         |> put_flash(:info, "¡Saldo recargado con éxito!")}
      _ -> {:noreply, put_flash(socket, :error, "Error en la recarga")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 pb-20">
      <%!-- BARRA SUPERIOR DE NAVEGACIÓN --%>
      <div class="bg-base-100 border-b border-base-300 px-4 py-4 mb-8 shadow-sm">
        <div class="max-w-7xl mx-auto flex justify-between items-center">
          <.link navigate={~p"/cliente/sorteos"} class="btn btn-ghost btn-sm gap-2 hover:bg-base-200">
            <.icon name="hero-arrow-left" class="size-4" /> Volver a Sorteos
          </.link>

          <div class="flex items-center gap-6">
             <div class="text-right">
                <p class="text-[10px] font-black opacity-40 uppercase tracking-widest">Saldo Disponible</p>
                <p class="text-2xl font-black leading-none">$<%= @usuario.saldo_virtual || 0 %></p>
             </div>
             <button phx-click="abrir_modal" class="btn btn-primary btn-sm rounded-xl gap-2 shadow-lg shadow-primary/20">
               <.icon name="hero-plus-circle" class="size-4" /> Recargar
             </button>
          </div>
        </div>
      </div>

      <div class="max-w-7xl mx-auto px-4 grid grid-cols-1 md:grid-cols-4 gap-12">

        <%!-- MENU LATERAL --%>
        <div class="md:col-span-1">
          <ul class="menu bg-base-100 p-4 rounded-2xl shadow-sm border border-base-300">
            <li class="menu-title opacity-40 text-[10px] uppercase font-black px-4 mb-3">Ajustes</li>
            <li>
              <button
                phx-click="set_seccion"
                phx-value-sec="info"
                class={["flex gap-4 py-3.5 rounded-xl", @seccion_activa == "info" && "bg-primary/10 text-primary font-bold"]}
              >
                <.icon name="hero-user" class="size-5" /> Mi Perfil
              </button>
            </li>
            <li>
              <button
                phx-click="set_seccion"
                phx-value-sec="seguridad"
                class={["flex gap-4 py-3.5 rounded-xl", @seccion_activa == "seguridad" && "bg-primary/10 text-primary font-bold"]}
              >
                <.icon name="hero-shield-check" class="size-5" /> Seguridad
              </button>
            </li>
          </ul>
        </div>

        <%!-- CONTENIDO PRINCIPAL --%>
        <div class="md:col-span-3 space-y-12">

          <%= if @seccion_activa == "info" do %>
            <div class="card bg-base-100 shadow-sm border border-base-300 overflow-hidden rounded-2xl">
              <div class="p-10 border-b border-base-300 flex justify-between items-center bg-base-100">
                <div>
                  <h2 class="text-3xl font-extrabold italic uppercase tracking-tight text-white">Información Personal</h2>
                  <div class="flex items-center gap-3 mt-2">
                    <div class="badge badge-success badge-xs"></div>
                    <span class="text-xs font-semibold opacity-60 uppercase tracking-wide">Usuario Verificado</span>
                  </div>
                </div>

                <%!-- ICONO DE USUARIO ESTILO OSCURO --%>
                <div class="bg-base-200 text-neutral rounded-2xl w-20 h-20 flex items-center justify-center border border-base-300 shadow-inner">
                  <.icon name="hero-user-solid" class="size-10" />
                </div>
              </div>

              <div class="p-4 divide-y divide-base-300/50">
                <%!-- FILA NOMBRE --%>
                <div class="p-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-base-200/20 transition-colors rounded-xl">
                  <div class="sm:w-1/3">
                    <p class="font-bold text-xs uppercase opacity-40">Nombre Completo</p>
                  </div>
                  <div class="flex-1">
                    <%= if @editando_campo == "nombre" do %>
                      <form phx-submit="guardar_cambios" class="flex gap-3">
                        <input type="hidden" name="campo" value="nombre" />
                        <input name="valor" value={@usuario.nombre} class="input input-bordered input-sm w-full max-w-sm" autofocus />
                        <button class="btn btn-primary btn-sm rounded-lg px-4">Ok</button>
                        <button type="button" phx-click="cancelar_edicion" class="btn btn-ghost btn-sm text-error">✕</button>
                      </form>
                    <% else %>
                      <p class="text-xl font-bold text-white"><%= @usuario.nombre %></p>
                    <% end %>
                  </div>
                  <%= if @editando_campo != "nombre" do %>
                    <button phx-click="editar" phx-value-campo="nombre" class="btn btn-link btn-xs text-primary font-bold no-underline hover:no-underline">Cambiar</button>
                  <% end %>
                </div>

                <%!-- FILA EMAIL --%>
                <div class="p-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-base-200/20 transition-colors rounded-xl">
                  <div class="sm:w-1/3">
                    <p class="font-bold text-xs uppercase opacity-40">Correo Electrónico</p>
                  </div>
                  <div class="flex-1">
                    <%= if @editando_campo == "email" do %>
                      <form phx-submit="guardar_cambios" class="flex gap-3">
                        <input type="hidden" name="campo" value="email" />
                        <input type="email" name="valor" value={@usuario.email} class="input input-bordered input-sm w-full max-w-sm" autofocus />
                        <button class="btn btn-primary btn-sm rounded-lg px-4">Ok</button>
                        <button type="button" phx-click="cancelar_edicion" class="btn btn-ghost btn-sm text-error">✕</button>
                      </form>
                    <% else %>
                      <p class="text-xl font-bold text-white"><%= @usuario.email %></p>
                    <% end %>
                  </div>
                  <%= if @editando_campo != "email" do %>
                    <button phx-click="editar" phx-value-campo="email" class="btn btn-link btn-xs text-primary font-bold no-underline hover:no-underline">Cambiar</button>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <%= if @seccion_activa == "seguridad" do %>
            <%!-- ... Mismo estilo oscuro aplicado a Seguridad ... --%>
            <div class="card bg-base-100 shadow-sm border border-base-300 rounded-2xl overflow-hidden">
              <div class="p-10 border-b border-base-300">
                <h2 class="text-3xl font-extrabold italic uppercase tracking-tight text-white">Seguridad</h2>
                <p class="text-sm opacity-60 mt-1">Protege tu cuenta actualizando tu contraseña.</p>
              </div>
              <div class="p-10">
                <div class="flex items-center justify-between bg-base-200 border border-base-300 p-8 rounded-2xl">
                  <div class="flex items-center gap-5">
                    <div class="p-4 bg-base-100 rounded-xl text-primary border border-base-300 shadow-inner">
                       <.icon name="hero-key" class="size-7" />
                    </div>
                    <div>
                      <p class="font-bold text-lg text-white">Contraseña</p>
                      <p class="text-sm opacity-50">Cambiada recientemente</p>
                    </div>
                  </div>

                  <%= if @editando_campo == "password" do %>
                    <form phx-submit="guardar_cambios" class="flex flex-col gap-4 w-full max-w-sm">
                      <input type="hidden" name="campo" value="password" />
                      <input type="password" name="valor" placeholder="Nueva clave" class="input input-bordered w-full" autofocus required />
                      <div class="flex gap-2.5">
                        <button class="btn btn-primary btn-block flex-1 rounded-xl">Actualizar</button>
                        <button type="button" phx-click="cancelar_edicion" class="btn btn-ghost btn-sm">✕</button>
                      </div>
                    </form>
                  <% else %>
                    <button phx-click="editar" phx-value-campo="password" class="btn btn-primary btn-outline btn-sm rounded-xl px-7">Cambiar Clave</button>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

        </div>
      </div>

      <%!-- MODAL DE RECARGA (Estilo DaisyUI oscuro) --%>
      <%= if @show_modal do %>
        <div class="modal modal-open backdrop-blur-sm">
          <div class="modal-box bg-base-100 border border-base-300 rounded-3xl p-10 max-w-md shadow-2xl">
            <h3 class="font-black text-3xl text-center mb-8 uppercase italic tracking-tighter text-white">Cargar Saldo</h3>
            <form phx-submit="confirmar_recarga" class="space-y-8">
              <div class="form-control">
                <label class="label"><span class="label-text font-black text-xs uppercase opacity-40">Monto del depósito (COP)</span></label>
                <select name="monto" class="select select-bordered w-full text-2xl font-black rounded-xl h-16">
                  <option value="10000">$10.000</option>
                  <option value="20000" selected>$20.000</option>
                  <option value="50000">$50.000</option>
                  <option value="100000">$100.000</option>
                </select>
              </div>

              <div class="space-y-3">
                <button type="submit" class="btn btn-primary btn-block btn-lg rounded-xl text-lg font-black uppercase shadow-xl shadow-primary/20">
                  Confirmar Pago
                </button>
                <button type="button" phx-click="cerrar_modal" class="btn btn-ghost btn-block font-bold opacity-60">
                  Cancelar
                </button>
              </div>
            </form>
          </div>
          <div phx-click="cerrar_modal" class="modal-backdrop bg-neutral-focus/60"></div>
        </div>
      <% end %>
    </div>
    """
  end
end
