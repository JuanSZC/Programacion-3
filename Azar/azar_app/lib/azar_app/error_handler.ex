defmodule AzarApp.ErrorHandler do
  @moduledoc false

  # Captura excepciones de Ecto/Postgres y las convierte en tuplas seguras
  def safe_get(repo_fun) do
    try do
      {:ok, repo_fun.()}
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
      Ecto.StaleEntryError -> {:error, :stale}
      e in Postgrex.Error -> {:error, e.postgres.message}
    end
  end
end
