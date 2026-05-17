defmodule AzarApp.Core.SorteoSupervisor do
  @moduledoc """
  Módulo AzarApp.Core.SorteoSupervisor: lógica relacionada con sorteosupervisor.
  """

  use DynamicSupervisor

  @doc """
  Breve: start_link.
  """
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Breve: iniciar_sorteo.
  """
  def iniciar_sorteo(datos_sorteo) do
    spec = {AzarApp.Core.SorteoServer, datos_sorteo}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc """
  Breve: restaurar_sorteos.
  """
  def restaurar_sorteos do
    if File.exists?("priv/data") do
      File.ls!("priv/data")
      |> Enum.filter(fn arch ->
        String.ends_with?(arch, ".json") and not String.starts_with?(arch, "cliente_")
      end)
      |> Enum.each(fn archivo ->
        nombre = String.replace(archivo, ".json", "")
        if sorteo = AzarApp.Core.GestorDatos.cargar_sorteo_json(nombre) do
          iniciar_sorteo(sorteo)
        end
      end)
    end
  end
end
