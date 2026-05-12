defmodule AzarApp.Premio do
  @enforce_keys [:id, :monto_bruto, :categoria]
  defstruct [
    :id,
    :monto_bruto,
    :categoria,
    :numero_ganador,
    monto_neto: 0,
    entregado: false,
    ganador_cedula: nil
  ]




  def nuevo(id, monto, categoria) when monto > 0 do

    impuesto = monto * 0.20
    neto = monto - impuesto

    {:ok, %__MODULE__{
      id: id,
      monto_bruto: monto,
      monto_neto: neto,
      categoria: categoria
    }}
  end

  def nuevo(_, _, _), do: {:error, :datos_invalidos}
end
