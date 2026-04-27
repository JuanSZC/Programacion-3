defmodule AzarApp.Billete do
  @enforce_keys [:codigo, :numero]
  defstruct [:codigo, :numero, precio: 2000, disponible: true]

  def nuevo(codigo, numero, precio) when precio >= 0 and byte_size(codigo) <= 5 do
    {:ok, %__MODULE__{codigo: codigo, numero: numero, precio: precio}}
  end
  def nuevo(_, _, _), do: {:error, :datos_invalidos}

end
