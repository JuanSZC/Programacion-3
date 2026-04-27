defmodule AzarApp.Sorteo do
  @enforce_keys [:id, :titulo, :fecha_ejecucion]
  defstruct [
    :id,
    :titulo,
    :fecha_ejecucion,
    pozo_acumulado: 0,
    numero_ganador: nil,
    boletos_participantes: [], # Lista de códigos de billetes
    estado: :programado # :programado, :realizado, :cancelado
  ]


  def nuevo(id, titulo, fecha, pozo_inicial \\ 0) when pozo_inicial >= 0 do
    {:ok, %__MODULE__{
      id: id,
      titulo: titulo,
      fecha_ejecucion: fecha,
      pozo_acumulado: pozo_inicial
    }}
  end


end
