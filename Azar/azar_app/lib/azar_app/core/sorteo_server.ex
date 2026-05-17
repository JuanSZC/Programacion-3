defmodule AzarApp.Core.SorteoServer do
  @moduledoc """
  Módulo AzarApp.Core.SorteoServer: lógica relacionada con sorteoserver.
  """

  use GenServer
  alias AzarApp.Core.GestorDatos

  @doc """
  Breve: start_link.
  """
  def start_link(datos_sorteo) do
    nombre_proceso = String.to_atom(datos_sorteo.nombre)
    GenServer.start_link(__MODULE__, datos_sorteo, name: nombre_proceso)
  end

  @doc """
  Breve: comprar_billete.
  """
  def comprar_billete(nombre_sorteo, info_compra) do
    GenServer.call(String.to_atom(nombre_sorteo), {:comprar_billete, info_compra})
  end

  @doc """
  Breve: devolver_compra.
  """
  def devolver_compra(nombre_sorteo, documento, numero) do
    GenServer.call(String.to_atom(nombre_sorteo), {:devolver_compra, documento, numero})
  end

  @doc """
  Breve: agregar_premio.
  """
  def agregar_premio(nombre_sorteo, premio) do
    GenServer.call(String.to_atom(nombre_sorteo), {:agregar_premio, premio})
  end

  @doc """
  Breve: ver_estado.
  """
  def ver_estado(nombre_sorteo) do
    GenServer.call(String.to_atom(nombre_sorteo), :ver_estado)
  end

  @impl true
  def init(datos_sorteo) do
    estado_inicial = GestorDatos.cargar_sorteo_json(datos_sorteo.nombre) || datos_sorteo
    GestorDatos.guardar_sorteo_json(estado_inicial.nombre, estado_inicial)
    {:ok, estado_inicial}
  end

  @impl true
  def handle_call(:ver_estado, _from, estado_actual) do
    {:reply, estado_actual, estado_actual}
  end

  @impl true
  def handle_call({:comprar_billete, compra}, _from, estado_actual) do
    compras = Map.get(estado_actual, :compras, []) ++ [compra]
    nuevo_estado = Map.put(estado_actual, :compras, compras)

    GestorDatos.guardar_sorteo_json(nuevo_estado.nombre, nuevo_estado)
    GestorDatos.registrar_bitacora("Compra en #{nuevo_estado.nombre}", "OK")
    {:reply, {:ok, "Compra exitosa"}, nuevo_estado}
  end

  @impl true
  def handle_call({:devolver_compra, documento, numero}, _from, estado_actual) do
    if estado_actual.estado == "pendiente" do
      compras = Map.get(estado_actual, :compras, [])
      compras_nuevas = Enum.reject(compras, fn c ->
        c.documento_cliente == documento and c.numero == numero
      end)

      nuevo_estado = Map.put(estado_actual, :compras, compras_nuevas)
      GestorDatos.guardar_sorteo_json(nuevo_estado.nombre, nuevo_estado)
      GestorDatos.registrar_bitacora("Devolucion en #{nuevo_estado.nombre} por #{documento}", "OK")

      {:reply, {:ok, "Devolucion exitosa"}, nuevo_estado}
    else
      GestorDatos.registrar_bitacora("Devolucion en #{estado_actual.nombre}", "Negado - Ya realizado")
      {:reply, {:error, "Sorteo ya realizado, no se aceptan devoluciones"}, estado_actual}
    end
  end

  @impl true
  def handle_call({:agregar_premio, premio}, _from, estado_actual) do
    premios = Map.get(estado_actual, :premios, []) ++ [premio]
    nuevo_estado = Map.put(estado_actual, :premios, premios)

    GestorDatos.guardar_sorteo_json(nuevo_estado.nombre, nuevo_estado)
    GestorDatos.registrar_bitacora("Premio agregado a #{nuevo_estado.nombre}", "OK")
    {:reply, {:ok, "Premio registrado"}, nuevo_estado}
  end
end
