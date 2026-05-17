defmodule Administrador do
  @moduledoc """
  Módulo Administrador: lógica relacionada con administrador.
  """

  @doc """
  Breve: crear_sorteo.
  """
  def crear_sorteo(nombre, fecha, valor_billete, fracciones, cantidad_billetes) do

    cond do

      nombre == "" ->
        {:error, "El nombre no puede estar vacío"}

      valor_billete <= 0 ->
        {:error, "El valor debe ser mayor a 0"}

      fracciones <= 0 ->
        {:error, "Las fracciones deben ser mayores a 0"}

      cantidad_billetes <= 0 ->
        {:error, "La cantidad de billetes debe ser mayor a 0"}

      true ->

        sorteo = %{
          nombre: nombre,
          fecha: fecha,
          valor_billete: valor_billete,
          fracciones: fracciones,
          cantidad_billetes: cantidad_billetes
        }

        {:ok, sorteo}

    end

  end

  @doc """
  Breve: ordenar_por_fecha.
  """
  def ordenar_por_fecha(lista_sorteos) do

   Enum.sort_by(lista_sorteos, fn sorteo ->
    sorteo.fecha_ejecucion
   end)

  end

  @doc """
  Breve: obtener_premios.
  """
  def obtener_premios(sorteo) do
  sorteo.premios
  end

  @doc """
  Breve: realizado.
  """
  def realizado?(sorteo) do
  sorteo.estado == :realizado
  end

  @doc """
  Breve: obtener_ganadores_por_premio.
  """
  def obtener_ganadores_por_premio(sorteo) do

  Enum.map(sorteo.premios, fn premio ->

    %{
      categoria: premio.categoria,
      ganador: premio.ganador_cedula,
      entregado: premio.entregado
    }

  end)

  end

  @doc """
  Breve: mostrar_info.
  """
  def mostrar_info(sorteo) do

  %{
    id: sorteo.id,
    titulo: sorteo.titulo,
    fecha: sorteo.fecha_ejecucion,
    estado: sorteo.estado,

    premios: obtener_premios(sorteo),

    numero_ganador:
      if realizado?(sorteo) do
        sorteo.numero_ganador
      else
        "Pendiente"
      end,

    ganadores:
      if realizado?(sorteo) do
        obtener_ganadores_por_premio(sorteo)
      else
        []
      end
   }

  end



  @doc """
  Breve: eliminar_sorteo.
  """
  def eliminar_sorteo(lista_sorteos, id_sorteo) do

  sorteo =
    Enum.find(lista_sorteos, fn s ->
      s.id == id_sorteo
    end)

  cond do

    sorteo == nil ->
      {:error, "Sorteo no encontrado"}

    length(sorteo.premios) > 0 ->
      {:error, "No se puede eliminar porque tiene premios"}

    true ->

      nueva_lista =
        Enum.reject(lista_sorteos, fn s ->
          s.id == id_sorteo
        end)

      {:ok, nueva_lista}

  end

end

@doc """
Breve: ordenar_alfabeticamente.
"""
def ordenar_alfabeticamente(lista_clientes) do

  Enum.sort_by(lista_clientes, fn cliente ->
    String.downcase(cliente.nombre)
  end)

end

@doc """
Breve: compradores_billete_completo.
"""
def compradores_billete_completo(compras, clientes) do

  compras
  |> Enum.filter(fn compra ->
    compra.tipo_compra == :completo
  end)
  |> Enum.map(fn compra ->

    Enum.find(clientes, fn cliente ->
      cliente.cedula == compra.cedula_cliente
    end)

  end)

end

@doc """
Breve: compradores_por_fraccion.
"""
def compradores_por_fraccion(compras, clientes) do

  compras
  |> Enum.filter(fn compra ->
    compra.tipo_compra == :fraccion
  end)
  |> Enum.map(fn compra ->

    Enum.find(clientes, fn cliente ->
      cliente.cedula == compra.cedula_cliente
    end)

  end)

end

@doc """
Breve: buscar_por_id.
"""
def buscar_por_id(lista_sorteos, id) do

  Enum.find(lista_sorteos, fn sorteo ->
    sorteo.id == id
  end)

end

@doc """
Breve: premios_entregados.
"""
def premios_entregados(sorteo) do

  Enum.filter(sorteo.premios, fn premio ->
    premio.entregado == true
  end)

end
@doc """
Breve: nombres_ganadores.
"""
def nombres_ganadores(sorteo, clientes) do

  premios_entregados(sorteo)
  |> Enum.map(fn premio ->

    cliente =
      Enum.find(clientes, fn cliente ->
        cliente.cedula == premio.ganador_cedula
      end)

    %{
      categoria: premio.categoria,
      ganador: cliente.nombre
    }

  end)

end

@doc """
Breve: dinero_recolectado.
"""
def dinero_recolectado(sorteo) do
  sorteo.pozo_acumulado
end

@doc """
Breve: total_premios_entregados.
"""
def total_premios_entregados(sorteo) do

  premios_entregados(sorteo)
  |> Enum.reduce(0, fn premio, acumulador ->

    acumulador + premio.monto_neto

  end)

end


@doc """
Breve: ganancias_o_perdidas.
"""
def ganancias_o_perdidas(sorteo) do

  dinero_recolectado(sorteo) -
    total_premios_entregados(sorteo)

end

@doc """
Breve: sorteos_pasados.
"""
def sorteos_pasados(lista_sorteos) do

  Enum.filter(lista_sorteos, fn sorteo ->
    sorteo.estado == :realizado
  end)

end

@doc """
Breve: resumen_sorteo.
"""
def resumen_sorteo(sorteo) do

  %{
    id: sorteo.id,
    titulo: sorteo.titulo,
    balance: ganancias_o_perdidas(sorteo)
  }

end

@doc """
Breve: balance_total.
"""
def balance_total(lista_sorteos) do

  lista_sorteos
  |> sorteos_pasados()
  |> Enum.reduce(0, fn sorteo, acumulador ->

    acumulador + ganancias_o_perdidas(sorteo)

  end)

end

@doc """
Breve: consultar_balance_sorteos.
"""
def consultar_balance_sorteos(lista_sorteos) do

  sorteos_realizados =
    sorteos_pasados(lista_sorteos)

  balances =
    Enum.map(sorteos_realizados, fn sorteo ->
      resumen_sorteo(sorteo)
    end)

  %{
    balances_por_sorteo: balances,
    balance_total_acumulado:
      balance_total(lista_sorteos)
  }

end

@doc """
Breve: crear_premio.
"""
def crear_premio(sorteo, id, monto_bruto, categoria) do

  case AzarApp.Premio.nuevo(id, monto_bruto, categoria) do

    {:ok, premio} ->

      sorteo_actualizado =
        agregar_premio(sorteo, premio)

      {:ok, sorteo_actualizado}

    {:error, motivo} ->

      {:error, motivo}

  end

end

@doc """
Breve: eliminar_premio.
"""
def eliminar_premio(sorteo, id_premio) do

  cond do

    length(sorteo.compras) > 0 ->

      {:error,
       "No se puede eliminar el premio porque hay compras asociadas"}

    true ->

      nuevos_premios =
        Enum.reject(sorteo.premios, fn premio ->
          premio.id == id_premio
        end)

      {:ok,
       %{sorteo | premios: nuevos_premios}}

  end

end

@doc """
Breve: sorteos_pendientes.
"""
def sorteos_pendientes(lista_sorteos, fecha_actual) do

  Enum.filter(lista_sorteos, fn sorteo ->

    sorteo.estado == :programado and
    sorteo.fecha_ejecucion <= fecha_actual

  end)

end

@doc """
Breve: generar_numero_ganador.
"""
def generar_numero_ganador(sorteo) do

  billete =
    Enum.random(sorteo.boletos_participantes)

  billete.numero

end

@doc """
Breve: ejecutar_sorteo.
"""
def ejecutar_sorteo(sorteo) do

  numero =
    generar_numero_ganador(sorteo)

  %{
    sorteo |
    numero_ganador: numero,
    estado: :realizado
  }

end

@doc """
Breve: obtener_ganadores.
"""
def obtener_ganadores(sorteo, clientes) do

  Enum.filter(clientes, fn cliente ->

    Enum.any?(sorteo.compras, fn compra ->

      compra.cedula_cliente == cliente.cedula

    end)

  end)

end

@doc """
Breve: notificar_ganadores.
"""
def notificar_ganadores(sorteo, clientes) do

  ganadores =
    obtener_ganadores(sorteo, clientes)

  Enum.map(ganadores, fn cliente ->

    """
    Felicidades #{cliente.nombre},
    ganaste el sorteo #{sorteo.titulo}
    """

  end)

end

@doc """
Breve: agregar_premio.
"""
def agregar_premio(sorteo, premio) do
  premios_actualizados = [premio | sorteo.premios]

  %{
    sorteo |
    premios: premios_actualizados
  }
end


end
