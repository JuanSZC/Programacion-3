defmodule AzarAppWeb.Cliente.SorteosLive do
  use AzarAppWeb, :live_view
  alias AzarApp.Sorteos
  alias AzarApp.Cuentas

  def mount(_params, session, socket) do
    usuario = if id = session["usuario_id"], do: Cuentas.obtener_usuario!(id), else: nil
    sorteos = Sorteos.list_sorteos_futuros()

    {:ok,
     socket
     |> assign(usuario: usuario)
     |> assign(sorteos: sorteos)
     |> assign(tab_activa: "actuales")}
  end

  def handle_event("cambiar_tab", %{"tab" => tab}, socket) do
    sorteos = case tab do
      "actuales" -> Sorteos.list_sorteos_futuros()
      "pasados"  -> Sorteos.list_sorteos_pasados()
    end

    {:noreply,
     socket
     |> assign(sorteos: sorteos)
     |> assign(tab_activa: tab)}
  end

  def render(assigns) do
    ~H"""
    <nav class="bg-base-100 border-b border-base-200 sticky top-0 z-50 px-4 py-3 shadow-md">
      <div class="max-w-7xl mx-auto flex justify-between items-center">
        <div class="flex items-center gap-2">
          <div class="bg-primary p-2 rounded-lg">
            <.icon name="hero-sparkles-solid" class="size-5 text-white" />
          </div>
          <span class="font-black text-lg tracking-tighter uppercase italic hidden sm:inline">AzarApp</span>
        </div>

        <div class="flex items-center gap-2 md:gap-4">
          <%= if @usuario do %>
            <div class="flex flex-col items-end bg-base-200 px-3 py-1 rounded-xl border border-base-300">
              <span class="text-[8px] font-black opacity-40 uppercase tracking-widest">Saldo</span>
              <span class="font-bold text-success text-xs md:text-sm leading-none">$ <%= @usuario.saldo_virtual %></span>
            </div>

            <.link navigate={~p"/cliente/perfil"} class="btn btn-ghost btn-circle btn-sm md:btn-md border border-base-300">
              <.icon name="hero-user" class="size-5" />
            </.link>

            <%!-- BOTÓN CORREGIDO: Sin puntos suspensivos ni errores de atributo --%>
            <.link
              href={~p"/sesion"}
              method="delete"
              class="btn btn-error btn-outline btn-sm md:btn-md rounded-xl font-bold gap-2 shadow-sm"
            >
              <span class="hidden md:inline text-xs">Cerrar Sesión</span>
              <.icon name="hero-arrow-right-on-rectangle" class="size-4 md:size-5" />
            </.link>
          <% end %>
        </div>
      </div>
    </nav>

    <div class="p-4 md:p-8 bg-base-200 min-h-screen">
      <div class="max-w-7xl mx-auto">
        <header class="flex flex-col md:flex-row justify-between items-start md:items-end mb-10 gap-6">
          <div class="animate-in fade-in slide-in-from-left-4 duration-500">
            <h1 class="text-4xl md:text-5xl font-black text-base-content tracking-tighter italic uppercase">
              Centro de <span class="text-primary">Sorteos</span>
            </h1>
            <p class="text-base-content/50 mt-2 font-bold tracking-tight">Participa y gana premios increíbles.</p>
          </div>

          <div class="tabs tabs-boxed bg-base-100 p-1.5 rounded-2xl shadow-xl border border-base-300 w-full md:w-auto">
            <button
              phx-click="cambiar_tab" phx-value-tab="actuales"
              class={"tab tab-lg flex-1 md:flex-none font-black transition-all px-8 rounded-xl " <> if(@tab_activa == "actuales", do: "tab-active !bg-primary !text-white", else: "hover:bg-base-200")}>
              🚀 ACTUALES
            </button>
            <button
              phx-click="cambiar_tab" phx-value-tab="pasados"
              class={"tab tab-lg flex-1 md:flex-none font-black transition-all px-8 rounded-xl " <> if(@tab_activa == "pasados", do: "tab-active !bg-primary !text-white", else: "hover:bg-base-200")}>
              ⌛ PASADOS
            </button>
          </div>
        </header>

        <%= if Enum.empty?(@sorteos) do %>
          <div class="flex flex-col items-center justify-center py-32 bg-base-100 rounded-[3rem] border-4 border-dashed border-base-300 shadow-inner">
            <h3 class="text-3xl font-black opacity-30 tracking-tighter italic uppercase text-center">
              <%= if @tab_activa == "actuales", do: "No hay sorteos activos", else: "Historial vacío" %>
            </h3>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <%= for sorteo <- @sorteos do %>
              <div class="card bg-base-100 shadow-xl border border-base-300 overflow-hidden group">
                <div class="card-body p-8">
                  <h2 class="card-title text-2xl font-black uppercase tracking-tighter mb-2"><%= sorteo.titulo %></h2>
                  <p class="text-base-content/50 text-sm"><%= sorteo.descripcion %></p>
                  <div class="flex items-center justify-between mt-6">
                    <span class="text-3xl font-black text-primary italic">$<%= sorteo.precio_ticket %></span>
                  </div>
                  <div class="card-actions mt-4">
                    <.link navigate={~p"/cliente/sorteos/#{sorteo.id}"} class="btn btn-primary btn-block rounded-2xl font-black">
                      PARTICIPAR
                    </.link>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
