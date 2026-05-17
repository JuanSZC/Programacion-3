defmodule AzarApp.Repo do
  @moduledoc """
  Módulo AzarApp.Repo: lógica relacionada con repo.
  """

  use Ecto.Repo,
    otp_app: :azar_app,
    adapter: Ecto.Adapters.Postgres
end
