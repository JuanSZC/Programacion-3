defmodule AzarApp.Sorteos.Scheduler do
  @moduledoc """
  GenServer que revisa periódicamente los sorteos activos con fecha vencida.

  Cada minuto verifica si algún sorteo llegó a su `fecha_ejecucion`:
  - Si cumple condiciones → lo ejecuta automáticamente.
  - Si NO las cumple  → lo cancela y reembolsa a los compradores.
  """
  use GenServer
  require Logger

  # Intervalo de revisión: cada 60 segundos
  @intervalo_ms 60_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Logger.info("[Scheduler] Iniciado. Revisando sorteos cada #{@intervalo_ms / 1000}s.")
    # Primera revisión al arrancar la app
    schedule_check()
    {:ok, state}
  end

  @impl true
  def handle_info(:verificar_sorteos, state) do
    case AzarApp.Sorteos.verificar_y_cancelar_expirados() do
      {:ok, 0} ->
        :ok

      {:ok, cantidad} ->
        Logger.info("[Scheduler] #{cantidad} sorteo(s) procesados por fecha vencida.")

      {:error, razon} ->
        Logger.error("[Scheduler] Error al verificar sorteos: #{inspect(razon)}")
    end

    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :verificar_sorteos, @intervalo_ms)
  end
end
