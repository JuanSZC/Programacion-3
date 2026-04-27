defmodule AzarApp.Repo do
  use Ecto.Repo,
    otp_app: :azar_app,
    adapter: Ecto.Adapters.Postgres
end
