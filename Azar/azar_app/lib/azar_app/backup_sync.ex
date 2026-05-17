# lib/azar_app/backup_sync.ex
defmodule AzarApp.BackupSync do
  @moduledoc """
  GenServer que escucha eventos PubSub y dispara
  el backup JSON automáticamente en cada cambio.
  """
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(_) do
    Phoenix.PubSub.subscribe(AzarApp.PubSub, "sorteos")
    # Exporta todo al arrancar
    AzarApp.Backup.exportar_todo()
    Logger.info("[BackupSync] Iniciado. Backup inicial generado.")
    {:ok, %{}}
  end

  # Cualquier evento en el canal "sorteos" dispara un backup completo
  @impl true
  def handle_info(_evento, state) do
    AzarApp.Backup.exportar_todo()
    {:noreply, state}
  end
end
