defmodule AzarApp.Core.AdminCore do
  @moduledoc """
  Módulo AzarApp.Core.AdminCore: lógica relacionada con admincore.
  """

  alias AzarApp.Core.SorteoSupervisor
  alias AzarApp.Core.GestorDatos

  @doc """
  Breve: crear_sorteo.
  """
  def crear_sorteo(nombre, fecha, valor_billete, cantidad_fracciones, cantidad_billetes) do
    datos_sorteo = %{
      nombre: nombre,
      fecha: fecha,
      valor_billete: valor_billete,
      cantidad_fracciones: cantidad_fracciones,
      cantidad_billetes: cantidad_billetes,
      compras: [],
      premios: [],
      estado: "pendiente"
    }

    case SorteoSupervisor.iniciar_sorteo(datos_sorteo) do
      {:ok, _pid} ->
        GestorDatos.registrar_bitacora("Crear sorteo #{nombre}", "OK")
        {:ok, "Sorteo creado exitosamente"}
      {:error, {:already_started, _pid}} ->
        GestorDatos.registrar_bitacora("Crear sorteo #{nombre}", "Negado - Ya existe")
        {:error, "El sorteo ya existe"}
      _error ->
        GestorDatos.registrar_bitacora("Crear sorteo #{nombre}", "Negado - Error interno")
        {:error, "No se pudo crear el sorteo"}
    end
  end

  @doc """
  Breve: listar_sorteos.
  """
  def listar_sorteos do
    GestorDatos.inicializar()

    File.ls!("priv/data")
    |> Enum.filter(&String.ends_with?(&1, ".json"))
    |> Enum.map(fn archivo ->
      nombre_sorteo = String.replace(archivo, ".json", "")
      GestorDatos.cargar_sorteo_json(nombre_sorteo)
    end)
    |> Enum.sort_by(&(&1.fecha))
  end
end
