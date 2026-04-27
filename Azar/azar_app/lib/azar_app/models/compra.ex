defmodule AzarApp.Compra do
  @enforce_keys [:id, :cedula_cliente, :codigo_billete, :monto_pagado]
  defstruct [
    :id,
    :cedula_cliente,
    :codigo_billete,
    :monto_pagado,
    fecha: nil,
    estado: :completada # :completada, :reembolsada
  ]


  def crear(id, cliente, billete) do
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


  def calcular_iva(%__MODULE__{monto_pagado: monto}), do: monto * 0.19
end
