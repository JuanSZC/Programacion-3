defmodule Premio do
  @derive  {Jason.Encoder, only: [:id, :nombre, :valor, :sorteo_id]}

  defstruct [:id, :nombre, :valor, :sorteo_id]

  def crear(id, nombre, valor, sorteo_id) do
    %Azar.Premio {id: id, nombre: nombre, valor: valor, sorteo_id: sorteo_id}
  end
end
