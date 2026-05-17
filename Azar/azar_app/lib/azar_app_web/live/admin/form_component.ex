defmodule AzarAppWeb.Admin.SorteoLive.FormComponent do
  @moduledoc """
  Módulo AzarAppWeb.Admin.SorteoLive.FormComponent: lógica relacionada con formcomponent.
  """

  use AzarAppWeb, :live_component
  alias AzarApp.Sorteos

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col max-h-[85vh]">
      <.form
        for={@form}
        id="sorteo-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="flex flex-col h-full"
      >
        <%!-- CONTENEDOR CON SCROLL (Ahora con Grid para formato horizontal) --%>
        <div class="flex-1 overflow-y-auto pr-2 pb-4 scrollbar-thin scrollbar-thumb-primary/20 scrollbar-track-transparent">

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">

            <%!-- COLUMNA IZQUIERDA: General y Negocio --%>
            <div class="space-y-4">
              <%!-- Sección Básica --%>
              <div class="bg-base-200/30 p-4 rounded-2xl border border-base-300/50 space-y-3 transition-colors hover:border-primary/20">
                <div class="flex items-center gap-2 mb-1">
                  <div class="p-1.5 bg-primary/10 rounded-lg">
                    <.icon name="hero-document-text-solid" class="size-4 text-primary" />
                  </div>
                  <h4 class="font-bold uppercase tracking-widest text-[10px] text-base-content/60">Info General</h4>
                </div>

                <div class="space-y-3">
                  <.input field={@form[:titulo]} type="text" label="Título del Sorteo" placeholder="Ej: Gran Rifa de Verano" />
                  <.input field={@form[:descripcion]} type="textarea" rows="2" label="Descripción" placeholder="Detalles del premio..." />
                </div>
              </div>

              <%!-- Sección de Modelo de Negocio --%>
              <div class="bg-base-200/30 p-4 rounded-2xl border border-base-300/50 space-y-3 transition-colors hover:border-secondary/20">
                <div class="flex items-center gap-2 mb-1">
                  <div class="p-1.5 bg-secondary/10 rounded-lg">
                    <.icon name="hero-banknotes-solid" class="size-4 text-secondary" />
                  </div>
                  <h4 class="font-bold uppercase tracking-widest text-[10px] text-base-content/60">Modelo de Negocio</h4>
                </div>

                <div class="grid grid-cols-1 gap-3">
                  <.input
                    field={@form[:tipo_premio]}
                    type="select"
                    label="Tipo de Sorteo"
                    options={[{"Sorteo Cantidad Fija", "fijo"}, {"Sorteo Cantidad Acumulada", "acumulado"}]}
                  />

                  <%= if Ecto.Changeset.get_field(@form.source, :tipo_premio) == "fijo" do %>
                    <.input field={@form[:premio_fijo]} type="number" label="Valor Premio Fijo ($)" placeholder="Ej: 5000" />
                    <p class="text-[9px] text-base-content/50 italic leading-tight">
                      * El recaudo total (tickets * precio) debe ser al menos el doble del premio.
                    </p>
                  <% else %>
                    <.input field={@form[:porcentaje_casa]} type="number" label="% Comisión Casa" placeholder="Ej: 30" />
                  <% end %>
                </div>
              </div>
            </div>

            <%!-- COLUMNA DERECHA: Configuración --%>
            <div class="space-y-4">
              <div class="bg-base-200/30 p-4 rounded-2xl border border-base-300/50 space-y-3 transition-colors hover:border-primary/20 h-full">
                <div class="flex items-center gap-2 mb-1">
                  <div class="p-1.5 bg-primary/10 rounded-lg">
                    <.icon name="hero-cog-8-tooth-solid" class="size-4 text-primary" />
                  </div>
                  <h4 class="font-bold uppercase tracking-widest text-[10px] text-base-content/60">Configuración del Evento</h4>
                </div>

                <div class="flex flex-col gap-3">
                  <.input field={@form[:precio_ticket]} type="number" step="0.01" label="Precio Ticket ($)" placeholder="0.00" />
                  <.input field={@form[:total_tickets]} type="number" label="Total de Tickets" placeholder="Ej: 1000 (Máx 1M)" />
                  <.input field={@form[:cantidad_ganadores]} type="number" label="Cant. Ganadores" placeholder="Ej: 1" />
                  <.input field={@form[:fecha_ejecucion]} type="datetime-local" label="Fecha del Sorteo" />
                </div>
              </div>
            </div>

          </div>
        </div>

        <%!-- ACCIONES (FIJAS AL FONDO) --%>
        <div class="flex flex-col sm:flex-row gap-3 mt-2 pt-3 border-t border-base-200 shrink-0 bg-base-100 z-10">
          <.link patch={@patch} class="btn btn-ghost h-12 flex-1 rounded-xl text-[10px] font-black uppercase tracking-widest text-base-content/50 hover:text-base-content hover:bg-base-200">
            Cancelar
          </.link>

          <button
            type="submit"
            phx-disable-with="Generando..."
            disabled={!@form.source.valid?}
            class={[
              "btn btn-primary h-12 flex-[2] rounded-xl shadow-lg shadow-primary/20 transition-all font-black text-[10px] uppercase tracking-widest gap-2 group",
              if(!@form.source.valid?, do: "btn-disabled opacity-50 grayscale cursor-not-allowed", else: "hover:-translate-y-1 hover:shadow-primary/30")
            ]}
          >
            Confirmar Sorteo
            <.icon name="hero-check-circle-solid" class="size-4 group-hover:scale-110 transition-transform" />
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{sorteo: sorteo} = assigns, socket) do
    changeset = Sorteos.change_sorteo(sorteo)

    {:ok,
      socket
      |> assign(assigns)
      |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"sorteo" => sorteo_params}, socket) do
    changeset =
      socket.assigns.sorteo
      |> Sorteos.change_sorteo(sorteo_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"sorteo" => sorteo_params}, socket) do
    case Sorteos.create_sorteo(sorteo_params) do
      {:ok, sorteo} ->
        send self(), {:saved, sorteo}
        {:noreply,
          socket
          |> put_flash(:info, "Sorteo creado exitosamente")
          |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
