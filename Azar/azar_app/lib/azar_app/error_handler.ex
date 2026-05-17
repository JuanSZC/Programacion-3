defmodule AzarApp.ErrorHandler do
  @moduledoc false

  @doc """
  Breve: safe_get.
  """
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
