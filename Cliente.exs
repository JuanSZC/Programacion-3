defmodule Cliente do
  defstruct [
    :nombre,
    :documento,
    :contrasena,
    :tarejeta,
    compras: [],
    premios: []
  ]
end
