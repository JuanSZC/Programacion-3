defmodule AzarApp.Cliente do
  @moduledoc """
  Módulo AzarApp.Cliente: lógica relacionada con cliente.
  """

  @enforce_keys [:cedula, :nombre, :email]
  defstruct [:cedula, :nombre, :email, edad: 0, saldo: 0, billetes_comprados: []]


  @doc """
  Breve: nuevo.
  """
  def nuevo(cedula, nombre, email, edad) when edad >= 18 and edad < 100 do
    if String.contains?(email, "@") do
      {:ok, %__MODULE__{cedula: cedula, nombre: nombre, email: email, edad: edad}}
    else
      {:error, :email_invalido}
    end
  end
  @doc """
  Breve: nuevo.
  """
  def nuevo(_c, _n, _e, _edad), do: {:error, :datos_invalidos}


end
