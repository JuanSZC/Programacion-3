defmodule AzarAppWeb.Admin.SorteosLive do
  use AzarAppWeb, :live_view
  alias AzarApp.Core.AdminCore

  def mount(_params, _session, socket) do
    sorteos =
      case AdminCore.listar_sorteos() do
        list when is_list(list) -> list
        _ -> []
      end

    {:ok, assign(socket, sorteos: sorteos)}
  end

  def handle_event("crear_sorteo", params, socket) do
    %{"nombre" => n, "fecha" => f, "valor" => v, "fracciones" => fr, "billetes" => b} = params

    case AdminCore.crear_sorteo(n, f, String.to_integer(v), String.to_integer(fr), String.to_integer(b)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "✨ Sorteo registrado exitosamente")
         |> assign(sorteos: AdminCore.listar_sorteos() || [])}
      {:error, msg} ->
        {:noreply, put_flash(socket, :error, "Error: #{msg}")}
    end
  end

  def render(assigns) do
    ~H"""
    <AzarAppWeb.AdminSidebar.sidebar current_page="sorteos">
      <div class="max-w-6xl mx-auto p-4 sm:p-8 space-y-10 relative z-10 animate-in fade-in duration-700">

        <%!-- HEADER DEL PANEL --%>
        <div class="flex flex-col gap-2">
          <div class="inline-flex items-center gap-2 bg-primary/10 px-4 py-2 rounded-full border border-primary/20 w-fit">
             <.icon name="hero-sparkles-solid" class="size-4 text-primary" />
             <span class="text-[10px] font-black uppercase tracking-[0.3em] text-primary">Centro de Mando</span>
          </div>
          <h1 class="text-5xl md:text-6xl font-black italic uppercase tracking-tighter text-base-content mt-2">
            Gestión <span class="text-primary drop-shadow-md">Sorteos</span>
          </h1>
          <p class="text-xs md:text-sm font-bold opacity-40 uppercase tracking-[0.3em]">
            Administración y control de eventos del sistema
          </p>
        </div>

        <%!-- FORMULARIO DE CREACIÓN (Efecto Glassmorphism) --%>
        <div class="bg-base-100/80 backdrop-blur-xl p-8 md:p-10 rounded-[3rem] border border-base-200/60 shadow-2xl relative overflow-hidden group">
           <%!-- Brillo de fondo sutil --%>
           <div class="absolute -top-24 -right-24 w-64 h-64 bg-primary/5 rounded-full blur-3xl group-hover:bg-primary/10 transition-colors duration-700"></div>

           <h2 class="text-2xl font-black mb-8 flex items-center gap-3 uppercase italic text-base-content relative z-10">
             <div class="p-3 bg-primary/10 text-primary rounded-2xl">
               <.icon name="hero-plus-circle-solid" class="size-6" />
             </div>
             Nuevo Registro
           </h2>

           <form phx-submit="crear_sorteo" class="grid grid-cols-1 md:grid-cols-5 gap-6 relative z-10">

              <%!-- Input Nombre (Ocupa 2 columnas en desktop) --%>
              <div class="form-control md:col-span-2">
                <label class="label p-0 ml-2 mb-2">
                  <span class="label-text font-black text-[10px] uppercase tracking-widest opacity-50">Nombre del Sorteo</span>
                </label>
                <input type="text" name="nombre" placeholder="Ej: Gran Sorteo Navideño" required class="input input-bordered h-14 rounded-2xl bg-base-200/50 border-none focus:bg-base-100 focus:ring-2 focus:ring-primary/50 transition-all font-bold text-base-content w-full" />
              </div>

              <%!-- Input Fecha --%>
              <div class="form-control md:col-span-1">
                <label class="label p-0 ml-2 mb-2">
                  <span class="label-text font-black text-[10px] uppercase tracking-widest opacity-50">Fecha</span>
                </label>
                <input type="date" name="fecha" required class="input input-bordered h-14 rounded-2xl bg-base-200/50 border-none focus:bg-base-100 focus:ring-2 focus:ring-primary/50 transition-all font-bold text-base-content w-full" />
              </div>

              <%!-- Input Valor --%>
              <div class="form-control md:col-span-2">
                <label class="label p-0 ml-2 mb-2">
                  <span class="label-text font-black text-[10px] uppercase tracking-widest opacity-50">Valor Individual ($)</span>
                </label>
                <div class="relative">
                  <span class="absolute inset-y-0 left-0 pl-4 flex items-center font-black text-base-content/30">$</span>
                  <input type="number" name="valor" placeholder="0.00" required class="input input-bordered h-14 pl-8 rounded-2xl bg-base-200/50 border-none focus:bg-base-100 focus:ring-2 focus:ring-primary/50 transition-all font-bold text-base-content w-full" />
                </div>
              </div>

              <%!-- Input Fracciones --%>
              <div class="form-control md:col-span-2">
                <label class="label p-0 ml-2 mb-2">
                  <span class="label-text font-black text-[10px] uppercase tracking-widest opacity-50">Fracciones por Billete</span>
                </label>
                <input type="number" name="fracciones" placeholder="Ej: 10" required class="input input-bordered h-14 rounded-2xl bg-base-200/50 border-none focus:bg-base-100 focus:ring-2 focus:ring-primary/50 transition-all font-bold text-base-content w-full" />
              </div>

              <%!-- Input Billetes --%>
              <div class="form-control md:col-span-3">
                <label class="label p-0 ml-2 mb-2">
                  <span class="label-text font-black text-[10px] uppercase tracking-widest opacity-50">Total de Billetes (Stock)</span>
                </label>
                <input type="number" name="billetes" placeholder="Ej: 1000" required class="input input-bordered h-14 rounded-2xl bg-base-200/50 border-none focus:bg-base-100 focus:ring-2 focus:ring-primary/50 transition-all font-bold text-base-content w-full" />
              </div>

              <%!-- Botón Submit --%>
              <button class="btn btn-primary h-14 md:col-span-5 rounded-2xl font-black text-white shadow-xl shadow-primary/30 mt-4 uppercase tracking-widest hover:-translate-y-1 hover:shadow-primary/40 transition-all group">
                Registrar en Sistema
                <.icon name="hero-check-circle-solid" class="size-5 ml-2 opacity-80 group-hover:scale-110 transition-transform" />
              </button>
           </form>
        </div>

        <%!-- LISTADO DE SORTEOS --%>
        <div class="bg-base-100/80 backdrop-blur-xl rounded-[3rem] border border-base-200/60 shadow-xl overflow-hidden min-h-[300px] flex flex-col">
          <%= if is_nil(@sorteos) or @sorteos == [] do %>
            <%!-- Estado Vacío Premium --%>
            <div class="flex-1 flex flex-col items-center justify-center py-20 px-4 text-center border-2 border-dashed border-base-300/50 rounded-[2.5rem] m-4">
              <div class="p-6 bg-base-200 rounded-full mb-6 relative">
                <div class="absolute inset-0 bg-primary/10 rounded-full animate-ping opacity-20"></div>
                <.icon name="hero-inbox-solid" class="size-12 text-base-content/20" />
              </div>
              <h4 class="text-2xl font-black text-base-content/50 uppercase italic tracking-tighter">No hay sorteos activos</h4>
              <p class="text-[10px] font-bold text-base-content/30 mt-2 uppercase tracking-widest max-w-xs">
                Utiliza el formulario superior para crear el primer evento en la plataforma.
              </p>
            </div>
          <% else %>
            <%!-- Tabla Estilizada --%>
            <div class="overflow-x-auto w-full p-2">
              <table class="table w-full border-collapse">
                <thead class="bg-base-200/50 text-base-content/50 font-black uppercase text-[10px] tracking-widest">
                  <tr>
                    <th class="py-6 pl-8 rounded-tl-3xl">Detalles del Sorteo</th>
                    <th>Fecha de Juego</th>
                    <th>Configuración</th>
                    <th class="text-center pr-8 rounded-tr-3xl">Estado</th>
                  </tr>
                </thead>
                <tbody class="font-medium">
                  <%= for sorteo <- @sorteos do %>
                    <tr class="hover:bg-primary/5 transition-colors border-b border-base-200/50 last:border-0 group">
                      <td class="py-6 pl-8">
                        <div class="flex items-center gap-4">
                          <div class="p-3 bg-base-200 rounded-xl group-hover:bg-primary/10 group-hover:text-primary transition-colors">
                            <.icon name="hero-ticket-solid" class="size-5" />
                          </div>
                          <div>
                            <div class="font-black italic text-lg uppercase tracking-tight text-base-content"><%= sorteo.nombre %></div>
                            <div class="text-[10px] font-bold opacity-40 uppercase tracking-widest mt-1">ID: <%= String.slice(sorteo.id || "000000", 0..7) %>...</div>
                          </div>
                        </div>
                      </td>
                      <td>
                        <div class="inline-flex items-center gap-2 px-3 py-1.5 bg-base-200 rounded-lg">
                          <.icon name="hero-calendar" class="size-4 opacity-50" />
                          <span class="font-bold text-xs uppercase tracking-wider"><%= sorteo.fecha %></span>
                        </div>
                      </td>
                      <td>
                        <div class="flex flex-col gap-1">
                          <span class="text-xs font-black text-primary uppercase tracking-widest"><%= sorteo.cantidad_billetes %> Billetes</span>
                          <span class="text-[10px] font-bold opacity-40 uppercase tracking-widest"><%= sorteo.cantidad_fracciones %> Fracciones c/u</span>
                        </div>
                      </td>
                      <td class="text-center pr-8">
                        <div class="inline-flex items-center gap-2 bg-warning/10 text-warning px-4 py-2 rounded-xl border border-warning/20">
                          <div class="size-2 bg-warning rounded-full animate-pulse"></div>
                          <span class="font-black text-[10px] uppercase tracking-widest italic">Pendiente</span>
                        </div>
                      </td>
                    </tr>
                  <% end %>
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
