defmodule AzarApp.Core.GestorDatos do
  @moduledoc """
  Módulo AzarApp.Core.GestorDatos: lógica relacionada con gestordatos.
  """

  @carpeta_datos "priv/data"
  @archivo_bitacora "#{@carpeta_datos}/bitacora.txt"

  @doc """
  Breve: inicializar.
  """
  def inicializar do
    File.mkdir_p!(@carpeta_datos)
  end

  @doc """
  Breve: guardar_sorteo_json.
  """
  def guardar_sorteo_json(nombre_sorteo, estado_sorteo) do
    inicializar()
    ruta = "#{@carpeta_datos}/#{nombre_sorteo}.json"
    contenido_json = Jason.encode!(estado_sorteo, pretty: true)
    File.write(ruta, contenido_json)
  end

  @doc """
  Breve: cargar_sorteo_json.
  """
  def cargar_sorteo_json(nombre_sorteo) do
    ruta = "#{@carpeta_datos}/#{nombre_sorteo}.json"

    if File.exists?(ruta) do
      contenido = File.read!(ruta)
      Jason.decode!(contenido, keys: :atoms)
    else
      nil
    end
  end

  @doc """
  Breve: registrar_bitacora.
  """
  def registrar_bitacora(solicitud, resultado) do
    inicializar()
    fecha_hora = NaiveDateTime.local_now() |> NaiveDateTime.to_string()
    linea = "[#{fecha_hora}] - Solicitud: #{solicitud} - Resultado: #{resultado}\n"

    IO.puts("==> LOG: " <> linea)
    File.write(@archivo_bitacora, linea, [:append])
  end
end
