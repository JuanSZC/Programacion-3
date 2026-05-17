defmodule AzarApp.BackupSync do
  @moduledoc false
  use GenServer
  require Logger

  @doc """
  Breve: start_link.
  """
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(_) do
    Phoenix.PubSub.subscribe(AzarApp.PubSub, "sorteos")
    AzarApp.Backup.exportar_todo()
    Logger.info("[BackupSync] Iniciado. Backup inicial generado.")
    {:ok, %{}}
  end

  @impl true
  def handle_info(_evento, state) do
    AzarApp.Backup.exportar_todo()
    {:noreply, state}
  end
end
