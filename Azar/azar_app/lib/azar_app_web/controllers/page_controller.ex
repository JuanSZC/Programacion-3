defmodule AzarAppWeb.PageController do
  @moduledoc """
  Módulo AzarAppWeb.PageController: lógica relacionada con pagecontroller.
  """

  use AzarAppWeb, :controller

  @doc """
  Breve: home.
  """
  def home(conn, _params) do
    render(conn, :home)
  end
end
