defmodule AzarApp.Billete do
  @moduledoc """
  Módulo AzarApp.Billete: lógica relacionada con billete.
  """

  @enforce_keys [:codigo, :numero]
  defstruct [:codigo, :numero, precio: 2000, disponible: true]

  @doc """
  Breve: nuevo.
  """
  def nuevo(codigo, numero, precio) when precio >= 0 and byte_size(codigo) <= 5 do
    {:ok, %__MODULE__{codigo: codigo, numero: numero, precio: precio}}
  end

  def nuevo(_, _, _), do: {:error, :datos_invalidos}

end
