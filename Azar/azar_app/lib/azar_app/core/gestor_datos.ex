defmodule AzarApp.Core.GestorDatos do
  @carpeta_datos "priv/data"
  @archivo_bitacora "#{@carpeta_datos}/bitacora.txt"

  def inicializar do
    File.mkdir_p!(@carpeta_datos)
  end

  def guardar_sorteo_json(nombre_sorteo, estado_sorteo) do
    inicializar()
    ruta = "#{@carpeta_datos}/#{nombre_sorteo}.json"
    contenido_json = Jason.encode!(estado_sorteo, pretty: true)
    File.write(ruta, contenido_json)
  end

  def cargar_sorteo_json(nombre_sorteo) do
    ruta = "#{@carpeta_datos}/#{nombre_sorteo}.json"

    if File.exists?(ruta) do
      contenido = File.read!(ruta)
      Jason.decode!(contenido, keys: :atoms)
    else
      nil
    end
  end

  def registrar_bitacora(solicitud, resultado) do
    inicializar()
    fecha_hora = NaiveDateTime.local_now() |> NaiveDateTime.to_string()
    linea = "[#{fecha_hora}] - Solicitud: #{solicitud} - Resultado: #{resultado}\n"

    IO.puts("==> LOG: " <> linea)
    File.write(@archivo_bitacora, linea, [:append])
  end
end
