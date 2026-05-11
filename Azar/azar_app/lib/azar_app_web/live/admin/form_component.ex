defmodule AzarAppWeb.Admin.SorteoLive.FormComponent do
  use AzarAppWeb, :live_component
  alias AzarApp.Sorteos

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col">
      <.form
        for={@form}
        id="sorteo-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="flex flex-col gap-6"
      >
        <%!-- Sección Básica --%>
        <div class="space-y-4">
          <.input field={@form[:titulo]} type="text" label="Título del Sorteo" placeholder="Ej: Gran Rifa de Verano" />
          <.input field={@form[:descripcion]} type="textarea" label="Descripción" placeholder="Detalles del premio, condiciones, etc..." />
        </div>

        <div class="divider my-0 opacity-30"></div>

        <%!-- Sección de Configuración --%>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input field={@form[:precio_ticket]} type="number" step="0.01" label="Precio Ticket ($)" placeholder="0.00" />
          <.input field={@form[:fecha_ejecucion]} type="datetime-local" label="Fecha del Sorteo" />
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input field={@form[:total_tickets]} type="number" label="Total de Tickets" placeholder="Ej: 1000 (Máx 1M)" />
          <.input field={@form[:cantidad_ganadores]} type="number" label="Cant. Ganadores" placeholder="Ej: 1 (Máx 25%)" />
        </div>

        <%!-- Acciones --%>
        <div class="flex flex-col-reverse sm:flex-row gap-3 mt-4 pt-4 border-t border-base-200">
          <.link patch={@patch} class="btn btn-ghost flex-1 rounded-xl text-base-content/70 hover:bg-base-200">
            Cancelar
          </.link>

          <button
            type="submit"
            phx-disable-with="Guardando..."
            disabled={!@form.source.valid?}
            class={[
              "btn btn-primary flex-1 rounded-xl shadow-lg shadow-primary/30 transition-all",
              !@form.source.valid? && "btn-disabled opacity-50"
            ]}
          >
            Confirmar y Generar Sorteo
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
