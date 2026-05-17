defmodule AzarApp.Core.SistemaCore do
  @moduledoc """
  Módulo AzarApp.Core.SistemaCore: lógica relacionada con sistemacore.
  """

  alias AzarApp.Core.GestorDatos
  alias AzarApp.Core.AdminCore

  @doc """
  Breve: actualizar_fecha_sistema.
  """
  def actualizar_fecha_sistema(nueva_fecha_str) do
    {:ok, nueva_fecha} = NaiveDateTime.from_iso8601(nueva_fecha_str <> " 00:00:00")

    AdminCore.listar_sorteos()
    |> Enum.filter(fn sorteo ->
      sorteo.estado == "pendiente" and
        debe_ejecutarse?(sorteo.fecha, nueva_fecha)
    end)
    |> Enum.each(&ejecutar_sorteo/1)

    GestorDatos.registrar_bitacora("Actualizacion de fecha a #{nueva_fecha_str}", "OK")
    {:ok, "Sistema actualizado. Sorteos pendientes ejecutados."}
  end

  defp debe_ejecutarse?(fecha_sorteo_str, nueva_fecha) do
    {:ok, fecha_sorteo} = NaiveDateTime.from_iso8601(fecha_sorteo_str <> " 00:00:00")
    NaiveDateTime.compare(fecha_sorteo, nueva_fecha) != :gt
  end

  defp ejecutar_sorteo(sorteo) do
    numero_ganador = Enum.random(1..sorteo.cantidad_billetes)

    sorteo_actualizado =
      sorteo
      |> Map.put(:estado, "realizado")
      |> Map.put(:numero_ganador, numero_ganador)

    GestorDatos.guardar_sorteo_json(sorteo_actualizado.nombre, sorteo_actualizado)

    GestorDatos.registrar_bitacora("Ejecucion sorteo #{sorteo.nombre}", "OK - Ganador: #{numero_ganador}")

    notificar_jugadores(sorteo_actualizado)
  end

  defp notificar_jugadores(sorteo) do
    IO.puts("\n=== NOTIFICACION GLOBAL ===")
    IO.puts("Sorteo #{sorteo.nombre} ejecutado.")
    IO.puts("Numero ganador oficial: #{sorteo.numero_ganador}")
    IO.puts("===========================\n")
  end
end
