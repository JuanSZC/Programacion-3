defmodule AzarApp.Compra do
  @moduledoc """
  Módulo AzarApp.Compra: lógica relacionada con compra.
  """

  @enforce_keys [:id, :cedula_cliente, :codigo_billete, :monto_pagado]
  defstruct [
    :id,
    :cedula_cliente,
    :codigo_billete,
    :monto_pagado,
    :tipo_compra,
    fecha: nil,
    estado: :completada # :completada, :reembolsada
  ]


  @doc """
  Breve: crear.
  """
  def crear(id, cliente, billete, _tipo \\ :compra) do
    cond do
      cliente.saldo < billete.precio ->
        {:error, :saldo_insuficiente}

      !billete.disponible ->
        {:error, :billete_no_disponible}

      true ->
        {:ok, %__MODULE__{
          id: id,
          cedula_cliente: cliente.cedula,
          codigo_billete: billete.codigo,
          monto_pagado: billete.precio,
          fecha: DateTime.utc_now()
        }}
    end
  end


  @doc """
  Breve: calcular_iva.
  """
  def calcular_iva(%__MODULE__{monto_pagado: monto}), do: monto * 0.19
end
