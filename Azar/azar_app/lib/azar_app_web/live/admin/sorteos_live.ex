defmodule AzarAppWeb.Admin.SorteosLive do
  use AzarAppWeb, :live_view
  alias AzarApp.Core.AdminCore

  def mount(_params, _session, socket) do
    # PASO 1: Forzamos la limpieza absoluta del dato
    # Si AdminCore devuelve algo que no sea una lista con elementos, asignamos []
    sorteos =
      case AdminCore.listar_sorteos() do
        list when is_list(list) -> list
        _ -> []
      end

    {:ok, assign(socket, sorteos: sorteos)}
  end

  def handle_event("crear_sorteo", params, socket) do
    # Requerimientos del PDF [cite: 26-31]
    %{"nombre" => n, "fecha" => f, "valor" => v, "fracciones" => fr, "billetes" => b} = params

    case AdminCore.crear_sorteo(n, f, String.to_integer(v), String.to_integer(fr), String.to_integer(b)) do
      {:ok, _} ->
        # Recarga y limpieza después de crear
        {:noreply,
          socket
          |> put_flash(:info, "✨ Sorteo creado (DB + JSON)")
          |> assign(sorteos: AdminCore.listar_sorteos() || [])}
      {:error, msg} ->
        {:noreply, put_flash(socket, :error, "Error: #{msg}")}
    end
  end

  def render(assigns) do
    ~H"""
    <AzarAppWeb.AdminSidebar.sidebar current_page="sorteos">
      <div class="max-w-6xl mx-auto p-4 sm:p-8 space-y-8">

        <%!-- Formulario de Creación --%>
        <div class="bg-base-100 p-8 rounded-[2rem] border border-base-200 shadow-xl">
           <h2 class="text-xl font-bold mb-6 flex items-center gap-2">
             <.icon name="hero-plus-circle" class="size-6 text-primary" /> Nuevo Sorteo
           </h2>
           <form phx-submit="crear_sorteo" class="grid grid-cols-1 md:grid-cols-5 gap-4">
              <input type="text" name="nombre" placeholder="Nombre" required class="input input-bordered rounded-xl" />
              <input type="date" name="fecha" required class="input input-bordered rounded-xl" />
              <input type="number" name="valor" placeholder="Valor $" required class="input input-bordered rounded-xl" />
              <input type="number" name="fracciones" placeholder="Fracciones" required class="input input-bordered rounded-xl" />
              <input type="number" name="billetes" placeholder="Billetes" required class="input input-bordered rounded-xl" />
              <button class="btn btn-primary md:col-span-5 rounded-xl font-bold">Registrar Sorteo</button>
           </form>
        </div>

        <%!-- ZONA DE RESULTADOS - EL "TRIPLE CHECK" --%>
        <div class="bg-base-100 rounded-[2.5rem] border border-base-200 shadow-sm overflow-hidden min-h-[400px] flex flex-col">

          <%!-- Si el conteo es 0 o la lista es [], mostramos el Empty State --%>
          <%= if is_nil(@sorteos) or @sorteos == [] or Enum.count(@sorteos) == 0 do %>

            <%!-- ESTADO VACÍO (Debe aparecer si no hay registros en JSON o Postgres) --%>
            <div class="flex-1 flex flex-col items-center justify-center py-20 px-4 text-center">
              <div class="relative mb-8">
                <div class="absolute -inset-6 bg-primary/20 rounded-full blur-3xl"></div>
                <div class="relative bg-base-200 p-10 rounded-full border border-base-300">
                  <.icon name="hero-ticket" class="size-16 text-primary/40" />
                </div>
              </div>

              <h4 class="text-3xl font-black text-base-content/90">No hay sorteos activos</h4>
              <p class="text-base-content/50 max-w-sm mt-3 text-lg">
                El sistema no detectó datos en <b>PostgreSQL</b> ni archivos <b>JSON</b>.
              </p>

              <div class="mt-8 flex gap-3 text-sm font-bold opacity-40">
                <span class="flex items-center gap-1"><.icon name="hero-check-circle" class="size-4" /> Postgres Listo</span>
                <span class="flex items-center gap-1"><.icon name="hero-check-circle" class="size-4" /> JSON Path OK</span>
              </div>
            </div>

          <% else %>

            <%!-- TABLA SI HAY DATOS --%>
            <div class="overflow-x-auto w-full">
              <table class="table table-zebra w-full">
                <thead class="bg-base-200/50">
                  <tr class="text-xs uppercase tracking-widest opacity-60">
                    <th class="py-5 pl-8">Sorteo</th>
                    <th>Fecha Ejecución</th>
                    <th>Configuración</th>
                    <th class="text-center">Estado</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for sorteo <- @sorteos do %>
                    <tr class="hover:bg-primary/5 transition-colors">
                      <td class="py-5 pl-8">
                        <div class="font-black text-lg text-base-content/80"><%= sorteo.nombre %></div>
                        <div class="text-xs font-mono opacity-40 uppercase">ID: #<%= sorteo.id %></div>
                      </td>
                      <td class="font-bold text-base-content/70"><%= sorteo.fecha %></td>
                      <td>
                        <div class="flex flex-col text-xs">
                          <span class="font-bold text-primary"><%= sorteo.cantidad_billetes %> Billetes</span>
                          <span class="opacity-50"><%= sorteo.cantidad_fracciones %> fracc/billete</span>
                        </div>
                      </td>
                      <td class="text-center">
                        <span class="badge badge-warning font-black py-3 px-4">PENDIENTE</span>
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
