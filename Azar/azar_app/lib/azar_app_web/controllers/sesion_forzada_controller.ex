defmodule AzarAppWeb.SesionForzadaController do
  use AzarAppWeb, :controller

  def cerrar(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:error, "Tu cuenta ha sido desactivada o eliminada por un administrador.")
    |> redirect(to: "/login")
  end
end
