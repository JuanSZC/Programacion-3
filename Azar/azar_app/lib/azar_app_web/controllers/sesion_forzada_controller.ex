defmodule AzarAppWeb.SesionForzadaController do
  @moduledoc """
  Módulo AzarAppWeb.SesionForzadaController: lógica relacionada con sesionforzadacontroller.
  """

  use AzarAppWeb, :controller

  @doc """
  Breve: cerrar.
  """
  def cerrar(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:error, "Tu cuenta ha sido desactivada o eliminada por un administrador.")
    |> redirect(to: "/login")
  end
end
