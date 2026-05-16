defmodule AzarAppWeb.Admin.UsuarioLive.Show do
  use AzarAppWeb, :live_view
  alias AzarApp.Cuentas
  alias AzarApp.Sorteos

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    usuario = Cuentas.obtener_usuario!(id)
    tickets = Sorteos.list_tickets_por_usuario(usuario.id)

    {:ok,
     socket
     |> assign(:usuario, usuario)
     |> assign(:tickets, tickets)
     |> assign(:editando, false)
     |> assign(:page_title, "Gestión: #{usuario.nombre}")}
  end

@impl true
def handle_event("toggle_activo", _, socket) do
  {:ok, usuario} = Cuentas.toggle_activo(socket.assigns.usuario)

  if not usuario.activo do
    Phoenix.PubSub.broadcast(AzarApp.PubSub, "usuario:#{usuario.id}", :forzar_logout)
  end

  {:noreply,
   socket
   |> assign(:usuario, usuario)
   |> put_flash(:info, "Usuario #{if usuario.activo, do: "activado", else: "desactivado"}")}
end

@impl true
def handle_event("eliminar_usuario", _, socket) do
  usuario = socket.assigns.usuario

  if Cuentas.tiene_tickets_activos?(usuario.id) do
    {:noreply, put_flash(socket, :error, "❌ No se puede eliminar: tiene tickets en sorteos activos.")}
  else
    Phoenix.PubSub.broadcast(AzarApp.PubSub, "usuario:#{usuario.id}", :forzar_logout)
    {:ok, _} = Cuentas.eliminar_usuario(usuario)

    {:noreply,
     socket
     |> put_flash(:info, "Usuario eliminado.")
     |> push_navigate(to: ~p"/admin/usuarios")}
  end
end

  @impl true
  def handle_event("editar", _, socket), do: {:noreply, assign(socket, :editando, true)}
  def handle_event("cancelar", _, socket), do: {:noreply, assign(socket, :editando, false)}

  @impl true
  def handle_event("guardar", %{"usuario" => params}, socket) do
    case Cuentas.actualizar_usuario(socket.assigns.usuario, params) do
      {:ok, usuario} ->
        {:noreply,
         socket
         |> assign(:usuario, usuario)
         |> assign(:editando, false)
         |> put_flash(:info, "Usuario actualizado correctamente")}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error al guardar los cambios")}
    end
  end

  @impl true
  def handle_event("ajustar_saldo", %{"monto" => monto, "operacion" => op}, socket) do
    monto_int = String.to_integer(monto)
    monto_final = if op == "sumar", do: monto_int, else: -monto_int

    case Cuentas.ajustar_saldo_admin(socket.assigns.usuario, monto_final) do
      {:ok, usuario} ->
        accion = if op == "sumar", do: "sumado", else: "descontado"
        {:noreply,
         socket
         |> assign(:usuario, usuario)
         |> put_flash(:info, "Saldo #{accion}: $#{monto_int}")}
      _ ->
        {:noreply, put_flash(socket, :error, "Error al ajustar el saldo")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AzarAppWeb.AdminSidebar.sidebar current_page="usuarios">
      <div class="max-w-5xl mx-auto space-y-8 animate-in fade-in duration-700 relative z-10">

        <%!-- HEADER --%>
        <div class="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-2">
          <div>
            <h1 class="text-4xl md:text-5xl font-black italic uppercase tracking-tighter text-base-content mt-2">
              Cliente <span class="text-secondary drop-shadow-md"><%= @usuario.nombre %></span>
            </h1>
          </div>
          <.link navigate={~p"/admin/usuarios"} class="btn btn-ghost rounded-[1.5rem] font-black text-xs uppercase tracking-widest text-base-content/60 gap-3 border border-transparent hover:border-base-300">
            <.icon name="hero-arrow-left-circle-solid" class="size-6" /> Volver
          </.link>
        </div>

        <%!-- TARJETA ESTADO + DATOS CLAVE --%>
        <div class="bg-gradient-to-r from-base-200/80 to-base-200/30 p-8 rounded-[3rem] border border-base-300/80 shadow-sm">
          <div class="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-6">

            <div class="flex items-center gap-6">
              <div class="size-20 rounded-[2rem] bg-secondary/10 border border-secondary/20 text-secondary flex items-center justify-center font-black text-4xl uppercase shadow-inner">
                <%= String.first(@usuario.nombre) %>
              </div>
              <div>
                <p class="text-2xl font-black italic uppercase tracking-tight"><%= @usuario.nombre %></p>
                <p class="text-xs font-bold text-base-content/50 uppercase tracking-widest mt-1"><%= @usuario.email %></p>
                <p class="text-[10px] font-bold text-base-content/40 uppercase tracking-widest mt-0.5">CI: <%= @usuario.cedula %></p>
              </div>
            </div>

            <div class="flex flex-wrap items-center gap-4">
              <div class="flex flex-col items-center bg-base-100/60 px-6 py-3 rounded-2xl border border-base-200">
                <span class="text-[9px] font-black uppercase tracking-widest text-base-content/40">Saldo</span>
                <span class="text-2xl font-black italic text-success">$<%= @usuario.saldo_virtual || 0 %></span>
              </div>
              <div class="flex flex-col items-center bg-base-100/60 px-6 py-3 rounded-2xl border border-base-200">
                <span class="text-[9px] font-black uppercase tracking-widest text-base-content/40">Tickets</span>
                <span class="text-2xl font-black italic text-primary"><%= length(@tickets) %></span>
              </div>
              <div class={[
                "flex flex-col items-center px-6 py-3 rounded-2xl border",
                if(@usuario.activo, do: "bg-success/10 border-success/20", else: "bg-error/10 border-error/20")
              ]}>
                <span class="text-[9px] font-black uppercase tracking-widest text-base-content/40">Estado</span>
                <span class={["text-base font-black italic uppercase", if(@usuario.activo, do: "text-success", else: "text-error")]}>
                  <%= if @usuario.activo, do: "Activo", else: "Inactivo" %>
                </span>
              </div>

              <button
                phx-click="toggle_activo"
                data-confirm={"¿#{if @usuario.activo, do: "Desactivar", else: "Activar"} este usuario?"}
                class={[
                  "btn h-12 px-6 rounded-2xl font-black text-xs uppercase tracking-widest transition-all",
                  if(@usuario.activo,
                    do: "bg-error/10 text-error border border-error/20 hover:bg-error hover:text-white",
                    else: "bg-success/10 text-success border border-success/20 hover:bg-success hover:text-white")
                ]}>
                <%= if @usuario.activo, do: "Desactivar", else: "Activar" %>
              </button>
              <button
                phx-click="eliminar_usuario"
                data-confirm="¿Eliminar permanentemente este usuario? Esta acción no se puede deshacer."
                class="btn bg-error/10 text-error border border-error/20 hover:bg-error hover:text-white h-12 px-6 rounded-2xl font-black text-xs uppercase tracking-widest transition-all gap-2">
                <.icon name="hero-trash-solid" class="size-4" />
                Eliminar Usuario
              </button>
            </div>
          </div>
        </div>

        <%!-- EDITAR DATOS PERSONALES --%>
        <div class="bg-base-100/80 backdrop-blur-xl p-8 rounded-[3rem] border border-base-200/60 shadow-xl">
          <div class="flex items-center justify-between mb-6">
            <div class="flex items-center gap-3">
              <div class="p-2 bg-secondary/10 rounded-xl">
                <.icon name="hero-pencil-square-solid" class="size-5 text-secondary" />
              </div>
              <h3 class="font-black text-xl italic uppercase tracking-tight">Datos Personales</h3>
            </div>
            <%= if not @editando do %>
              <button phx-click="editar" class="btn btn-ghost btn-sm bg-base-200 hover:bg-secondary/10 hover:text-secondary rounded-xl font-black text-[10px] uppercase tracking-widest">
                Editar
              </button>
            <% end %>
          </div>

          <%= if @editando do %>
            <form phx-submit="guardar" class="grid grid-cols-1 md:grid-cols-2 gap-4 animate-in fade-in duration-300">
              <div class="form-control">
                <label class="text-[10px] font-black uppercase tracking-widest text-base-content/50 mb-1.5 ml-1">Nombre</label>
                <input type="text" name="usuario[nombre]" value={@usuario.nombre} required
                  class="input input-bordered h-12 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-secondary/50 font-bold" />
              </div>
              <div class="form-control">
                <label class="text-[10px] font-black uppercase tracking-widest text-base-content/50 mb-1.5 ml-1">Cédula</label>
                <input type="text" name="usuario[cedula]" value={@usuario.cedula} required
                  class="input input-bordered h-12 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-secondary/50 font-bold" />
              </div>
              <div class="form-control md:col-span-2">
                <label class="text-[10px] font-black uppercase tracking-widest text-base-content/50 mb-1.5 ml-1">Correo</label>
                <input type="email" name="usuario[email]" value={@usuario.email} required
                  class="input input-bordered h-12 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-secondary/50 font-bold" />
              </div>
              <div class="md:col-span-2 flex gap-3 pt-2">
                <button type="submit" class="btn btn-secondary flex-1 h-12 rounded-2xl font-black text-[10px] uppercase tracking-widest shadow-lg shadow-secondary/20">
                  Guardar Cambios <.icon name="hero-check-circle-solid" class="size-4" />
                </button>
                <button type="button" phx-click="cancelar" class="btn btn-ghost bg-base-200 h-12 rounded-2xl font-black text-[10px] uppercase tracking-widest">
                  Cancelar
                </button>
              </div>
            </form>
          <% else %>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <%= for {label, valor, icon} <- [{"Nombre", @usuario.nombre, "hero-user-solid"}, {"Cédula", @usuario.cedula, "hero-credit-card-solid"}, {"Correo", @usuario.email, "hero-envelope-solid"}] do %>
                <div class="bg-base-200/40 p-4 rounded-2xl border border-base-300/30">
                  <div class="flex items-center gap-2 mb-1">
                    <.icon name={icon} class="size-3.5 text-base-content/40" />
                    <span class="text-[9px] font-black uppercase tracking-widest text-base-content/40"><%= label %></span>
                  </div>
                  <p class="font-black text-sm text-base-content italic truncate"><%= valor %></p>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <%!-- AJUSTE DE SALDO --%>
        <div class="bg-base-100/80 backdrop-blur-xl p-8 rounded-[3rem] border border-base-200/60 shadow-xl">
          <div class="flex items-center gap-3 mb-6">
            <div class="p-2 bg-success/10 rounded-xl">
              <.icon name="hero-banknotes-solid" class="size-5 text-success" />
            </div>
            <h3 class="font-black text-xl italic uppercase tracking-tight">Ajuste de Saldo</h3>
          </div>

          <form phx-submit="ajustar_saldo" class="flex flex-col sm:flex-row gap-4 items-end">
            <div class="form-control flex-1">
              <label class="text-[10px] font-black uppercase tracking-widest text-base-content/50 mb-1.5 ml-1">Monto ($)</label>
              <div class="relative">
                <span class="absolute inset-y-0 left-4 flex items-center font-black text-base-content/30">$</span>
                <input type="number" name="monto" min="1" placeholder="0" required
                  class="input input-bordered h-12 w-full pl-8 rounded-2xl bg-base-200/50 border-none focus:ring-2 focus:ring-primary/40 font-bold" />
              </div>
            </div>
            <input type="hidden" name="operacion" id="op-hidden" value="sumar" />
            <div class="flex gap-3">
              <button type="submit" phx-click={JS.set_attribute({"value", "sumar"}, to: "#op-hidden")}
                class="btn btn-success h-12 px-6 rounded-2xl font-black text-[10px] uppercase tracking-widest shadow-lg shadow-success/20">
                <.icon name="hero-plus-solid" class="size-4" /> Sumar
              </button>
              <button type="submit" phx-click={JS.set_attribute({"value", "restar"}, to: "#op-hidden")}
                class="btn bg-error/10 text-error border border-error/20 hover:bg-error hover:text-white h-12 px-6 rounded-2xl font-black text-[10px] uppercase tracking-widest transition-all">
                <.icon name="hero-minus-solid" class="size-4" /> Restar
              </button>
            </div>
          </form>
        </div>

        <%!-- TICKETS DEL USUARIO --%>
        <div class="bg-base-100/80 backdrop-blur-xl p-8 rounded-[3rem] border border-base-200/60 shadow-xl">
          <div class="flex items-center gap-3 mb-6">
            <div class="p-2 bg-primary/10 rounded-xl">
              <.icon name="hero-ticket-solid" class="size-5 text-primary" />
            </div>
            <h3 class="font-black text-xl italic uppercase tracking-tight">
              Tickets Comprados <span class="text-primary">(<%= length(@tickets) %>)</span>
            </h3>
          </div>

          <%= if Enum.empty?(@tickets) do %>
            <div class="flex flex-col items-center justify-center py-12 text-base-content/30">
              <.icon name="hero-ticket-solid" class="size-12 mb-3 opacity-20" />
              <p class="font-black uppercase tracking-widest text-sm">Sin tickets</p>
            </div>
          <% else %>
            <div class="overflow-x-auto rounded-2xl border border-base-200/60">
              <table class="table w-full">
                <thead class="bg-base-200/50 text-base-content/50 text-[10px] uppercase tracking-widest font-black">
                  <tr>
                    <th class="py-4 pl-6">Sorteo</th>
                    <th>Número</th>
                    <th>Estado</th>
                    <th class="pr-6 text-right">Precio</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-base-200/50">
                  <tr :for={ticket <- @tickets} class="hover:bg-base-200/20 transition-colors">
                    <td class="py-4 pl-6 font-bold text-sm italic uppercase text-base-content/80">
                      <%= ticket.sorteo.titulo %>
                    </td>
                    <td>
                      <span class="inline-flex items-center justify-center size-10 rounded-xl bg-primary/10 text-primary font-black text-lg">
                        <%= ticket.numero %>
                      </span>
                    </td>
                    <td>
                      <span class={[
                        "px-3 py-1 rounded-lg font-black text-[9px] uppercase tracking-widest border",
                        if(ticket.estado == "vendido",
                          do: "bg-success/10 text-success border-success/20",
                          else: "bg-base-200 text-base-content/50 border-base-300")
                      ]}>
                        <%= ticket.estado %>
                      </span>
                    </td>
                    <td class="pr-6 text-right font-black text-primary italic">$<%= ticket.sorteo.precio_ticket %></td>
                  </tr>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>

      </div>
    </AzarAppWeb.AdminSidebar.sidebar>
    """
  end
end
