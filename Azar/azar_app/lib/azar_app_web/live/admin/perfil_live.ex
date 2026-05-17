defmodule AzarAppWeb.Admin.PerfilLive do
  @moduledoc """
  Módulo AzarAppWeb.Admin.PerfilLive: lógica relacionada con perfillive.
  """

  use AzarAppWeb, :live_view
  alias AzarApp.Cuentas

  @impl true
  def mount(_params, session, socket) do
    case session["usuario_id"] do
      nil ->
        {:ok, push_navigate(socket, to: "/admin/login")}

      id ->
        admin = Cuentas.obtener_usuario!(id)

        {:ok,
         socket
         |> assign(:admin, admin)
         |> assign(:editando, nil)
         |> assign(:page_title, "Mi Perfil Admin")}
    end
  end

  @impl true
  def handle_event("editar", %{"campo" => campo}, socket),
    do: {:noreply, assign(socket, :editando, campo)}

  @doc """
  Breve: handle_event.
  """
  def handle_event("cancelar", _, socket),
    do: {:noreply, assign(socket, :editando, nil)}

  @impl true
  def handle_event("guardar", %{"campo" => campo, "valor" => valor}, socket) do
    case Cuentas.actualizar_campo_usuario(socket.assigns.admin, campo, valor) do
      {:ok, admin} ->
        {:noreply,
         socket
         |> assign(:admin, admin)
         |> assign(:editando, nil)
         |> put_flash(:info, "#{String.capitalize(campo)} actualizado correctamente")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "❌ Error al guardar. Verifica los datos.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AzarAppWeb.AdminSidebar.sidebar current_page="perfil">
      <div class="max-w-2xl mx-auto space-y-8 animate-in fade-in duration-700 relative z-10">

        <%!-- HEADER --%>
        <div class="flex flex-col gap-2">
          <div class="inline-flex items-center gap-2 bg-primary/10 px-4 py-2 rounded-full border border-primary/20 w-fit">
            <.icon name="hero-shield-check-solid" class="size-4 text-primary" />
            <span class="text-[10px] font-black uppercase tracking-[0.3em] text-primary">Cuenta Protegida</span>
          </div>
          <h1 class="text-4xl md:text-5xl font-black italic uppercase tracking-tighter text-base-content mt-1">
            Mi <span class="text-primary drop-shadow-md">Perfil</span>
          </h1>
          <p class="text-xs font-bold opacity-40 uppercase tracking-[0.2em]">
            Gestiona tus credenciales de administrador
          </p>
        </div>

        <%!-- AVATAR + INFO BÁSICA --%>
        <div class="bg-gradient-to-br from-base-200/80 to-base-200/30 p-8 rounded-[3rem] border border-base-300/80 shadow-sm flex items-center gap-6">
          <div class="size-24 rounded-[2rem] bg-primary/10 border-2 border-primary/20 text-primary flex items-center justify-center font-black text-4xl uppercase shadow-inner shrink-0">
            <%= String.first(@admin.nombre) %>
          </div>
          <div>
            <p class="text-2xl font-black italic uppercase tracking-tight text-base-content">
              <%= @admin.nombre %>
            </p>
            <p class="text-xs font-bold text-base-content/50 uppercase tracking-widest mt-1">
              <%= @admin.email %>
            </p>
            <div class="flex items-center gap-2 mt-3 w-fit bg-primary/10 px-3 py-1.5 rounded-xl border border-primary/20">
              <.icon name="hero-shield-check-solid" class="size-3.5 text-primary" />
              <span class="text-[9px] font-black uppercase tracking-widest text-primary">Administrador</span>
            </div>
          </div>
        </div>

        <%!-- CREDENCIALES --%>
        <div class="bg-base-100/80 backdrop-blur-xl rounded-[3rem] border border-base-200/60 shadow-xl overflow-hidden">

          <div class="p-6 border-b border-base-200/60 flex items-center gap-3 bg-base-200/30">
            <div class="p-2 bg-primary/10 rounded-xl">
              <.icon name="hero-identification-solid" class="size-5 text-primary" />
            </div>
            <h3 class="font-black text-lg italic uppercase tracking-tight">Credenciales</h3>
          </div>

          <div class="divide-y divide-base-200/60">

            <%!-- NOMBRE --%>
            <div class="p-6 flex flex-col md:flex-row md:items-center justify-between gap-4 hover:bg-base-200/20 transition-colors group">
              <div class="md:w-1/4">
                <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 flex items-center gap-1.5">
                  <.icon name="hero-user-solid" class="size-3" /> Nombre
                </p>
              </div>
              <div class="flex-1">
                <%= if @editando == "nombre" do %>
                  <form phx-submit="guardar" class="flex gap-2">
                    <input type="hidden" name="campo" value="nombre" />
                    <input name="valor" value={@admin.nombre} required autofocus
                      class="input input-bordered h-11 flex-1 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-primary/50 font-bold" />
                    <button class="btn btn-primary btn-sm h-11 rounded-xl px-4">
                      <.icon name="hero-check-solid" class="size-4" />
                    </button>
                    <button type="button" phx-click="cancelar" class="btn btn-ghost btn-sm h-11 rounded-xl bg-base-200 hover:text-error px-4">
                      <.icon name="hero-x-mark-solid" class="size-4" />
                    </button>
                  </form>
                <% else %>
                  <p class="font-black text-lg italic text-base-content"><%= @admin.nombre %></p>
                <% end %>
              </div>
              <%= if @editando != "nombre" do %>
                <button phx-click="editar" phx-value-campo="nombre"
                  class="btn btn-ghost btn-sm bg-base-200/50 hover:bg-primary/10 hover:text-primary rounded-xl font-black text-[9px] uppercase tracking-widest opacity-0 group-hover:opacity-100 transition-all">
                  Editar
                </button>
              <% end %>
            </div>

            <%!-- EMAIL --%>
            <div class="p-6 flex flex-col md:flex-row md:items-center justify-between gap-4 hover:bg-base-200/20 transition-colors group">
              <div class="md:w-1/4">
                <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 flex items-center gap-1.5">
                  <.icon name="hero-envelope-solid" class="size-3" /> Correo
                </p>
              </div>
              <div class="flex-1">
                <%= if @editando == "email" do %>
                  <form phx-submit="guardar" class="flex gap-2">
                    <input type="hidden" name="campo" value="email" />
                    <input type="email" name="valor" value={@admin.email} required autofocus
                      class="input input-bordered h-11 flex-1 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-primary/50 font-bold" />
                    <button class="btn btn-primary btn-sm h-11 rounded-xl px-4">
                      <.icon name="hero-check-solid" class="size-4" />
                    </button>
                    <button type="button" phx-click="cancelar" class="btn btn-ghost btn-sm h-11 rounded-xl bg-base-200 hover:text-error px-4">
                      <.icon name="hero-x-mark-solid" class="size-4" />
                    </button>
                  </form>
                <% else %>
                  <p class="font-bold text-base text-base-content/80"><%= @admin.email %></p>
                <% end %>
              </div>
              <%= if @editando != "email" do %>
                <button phx-click="editar" phx-value-campo="email"
                  class="btn btn-ghost btn-sm bg-base-200/50 hover:bg-primary/10 hover:text-primary rounded-xl font-black text-[9px] uppercase tracking-widest opacity-0 group-hover:opacity-100 transition-all">
                  Editar
                </button>
              <% end %>
            </div>

            <%!-- CONTRASEÑA --%>
            <div class="p-6 flex flex-col md:flex-row md:items-center justify-between gap-4 hover:bg-base-200/20 transition-colors group">
              <div class="md:w-1/4">
                <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 flex items-center gap-1.5">
                  <.icon name="hero-key-solid" class="size-3" /> Contraseña
                </p>
              </div>
              <div class="flex-1">
                <%= if @editando == "password" do %>
                  <form phx-submit="guardar" class="flex flex-col sm:flex-row gap-2">
                    <input type="hidden" name="campo" value="password" />
                    <input type="password" name="valor" placeholder="Nueva contraseña (mín. 8 caracteres)"
                      required minlength="8" autofocus
                      class="input input-bordered h-11 flex-1 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-primary/50 font-bold tracking-widest" />
                    <div class="flex gap-2">
                      <button class="btn btn-primary btn-sm h-11 rounded-xl px-4">
                        <.icon name="hero-check-solid" class="size-4" />
                      </button>
                      <button type="button" phx-click="cancelar" class="btn btn-ghost btn-sm h-11 rounded-xl bg-base-200 hover:text-error px-4">
                        <.icon name="hero-x-mark-solid" class="size-4" />
                      </button>
                    </div>
                  </form>
                <% else %>
                  <p class="font-black text-base-content/40 tracking-[0.4em]">••••••••</p>
                <% end %>
              </div>
              <%= if @editando != "password" do %>
                <button phx-click="editar" phx-value-campo="password"
                  class="btn btn-ghost btn-sm bg-base-200/50 hover:bg-primary/10 hover:text-primary rounded-xl font-black text-[9px] uppercase tracking-widest opacity-0 group-hover:opacity-100 transition-all">
                  Cambiar
                </button>
              <% end %>
            </div>

          </div>
        </div>

        <%!-- INFO DE SESIÓN --%>
        <div class="bg-base-100/80 backdrop-blur-xl rounded-[3rem] border border-base-200/60 shadow-xl p-8">
          <div class="flex items-center gap-3 mb-6">
            <div class="p-2 bg-base-200 rounded-xl">
              <.icon name="hero-clock-solid" class="size-5 text-base-content/50" />
            </div>
            <h3 class="font-black text-lg italic uppercase tracking-tight">Info de Sesión</h3>
         <%!-- ZONA DE PELIGRO: LIMPIEZA TOTAL --%>
    <div class="bg-error/5 backdrop-blur-xl rounded-[3rem] border border-error/20 shadow-xl p-8">
    <div class="flex items-center gap-3 mb-4">
    <div class="p-2 bg-error/10 rounded-xl">
      <.icon name="hero-trash-solid" class="size-5 text-error" />
    </div>
    <h3 class="font-black text-lg italic uppercase tracking-tight text-error">Zona de Peligro</h3>
    </div>

    <p class="text-[11px] font-bold text-base-content/50 uppercase tracking-wider leading-relaxed mb-6">
    Esta acción elimina <span class="text-error font-black">permanentemente</span> todos los sorteos,
    tickets, usuarios no predeterminados y el archivo de auditoría.
    Los usuarios <span class="font-black text-base-content/70">admin@azar.com</span> y
    <span class="font-black text-base-content/70">cliente@azar.com</span> se conservan con saldo en $0.
    Esta acción es <span class="text-error font-black">irreversible</span>.
    </p>

    <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-error/5 border border-error/15 p-5 rounded-2xl">
    <div class="flex items-center gap-3">
      <.icon name="hero-exclamation-triangle-solid" class="size-6 text-error shrink-0" />
      <div>
        <p class="font-black text-sm text-error uppercase tracking-wide">Limpiar Sistema Completo</p>
        <p class="text-[10px] text-base-content/40 uppercase tracking-widest mt-0.5">
          Sorteos · Tickets · Usuarios extra · Logs · Saldos
        </p>
      </div>
    </div>

    <button
      phx-click="limpiar_sistema"
      data-confirm="⚠️ ADVERTENCIA: Esto eliminará TODOS los sorteos, tickets, usuarios extra y logs del sistema. Los usuarios predeterminados se conservan con saldo $0. ¿Estás completamente seguro?"
      class="btn bg-error text-white border-error hover:bg-error/80 h-12 px-8 rounded-2xl font-black text-[10px] uppercase tracking-widest shadow-lg shadow-error/20 transition-all hover:-translate-y-0.5 gap-2 shrink-0">
      <.icon name="hero-trash-solid" class="size-4" />
      Limpiar Todo
    </button>
    </div>
    </div>
            </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="bg-base-200/40 p-4 rounded-2xl border border-base-300/30">
              <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-1">Último acceso</p>
              <p class="font-black text-sm italic text-base-content">
                <%= if @admin.ultimo_login do
                  Calendar.strftime(@admin.ultimo_login, "%d %b %Y, %H:%M")
                else
                  "Sin registro"
                end %>
              </p>
            </div>
            <div class="bg-base-200/40 p-4 rounded-2xl border border-base-300/30">
              <p class="text-[9px] font-black uppercase tracking-widest text-base-content/40 mb-1">Miembro desde</p>
              <p class="font-black text-sm italic text-base-content">
                <%= Calendar.strftime(@admin.inserted_at, "%d %b %Y") %>
              </p>
            </div>
            <div class="sm:col-span-2 bg-success/5 p-4 rounded-2xl border border-success/15 flex items-center gap-3">
              <div class="size-2.5 rounded-full bg-success animate-pulse shadow-[0_0_8px_rgba(0,255,0,0.6)]"></div>
              <p class="text-[10px] font-black uppercase tracking-widest text-success/80">
                Sesión activa · Rol: Administrador
              </p>
            </div>
          </div>
        </div>

      </div>
    </AzarAppWeb.AdminSidebar.sidebar>
    """
  end
end
