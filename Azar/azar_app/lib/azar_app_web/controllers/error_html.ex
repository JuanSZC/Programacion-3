defmodule AzarAppWeb.ErrorHTML do
  @moduledoc false
  use AzarAppWeb, :html


  @doc """
  Breve: render.
  """
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
