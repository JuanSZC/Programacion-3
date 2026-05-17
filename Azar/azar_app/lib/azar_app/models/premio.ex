defmodule AzarApp.Premio do
  @moduledoc """
  Módulo AzarApp.Premio: lógica relacionada con premio.
  """

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




  @doc """
  Breve: nuevo.
  """
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

  @doc """
  Breve: nuevo.
  """
  def nuevo(_, _, _), do: {:error, :datos_invalidos}
end
