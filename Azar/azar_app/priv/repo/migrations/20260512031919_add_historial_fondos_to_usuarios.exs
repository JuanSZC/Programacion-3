defmodule AzarApp.Repo.Migrations.AddHistorialFondosToUsuarios do
  use Ecto.Migration

  def change do
    alter table(:usuarios) do
      add :total_recargado, :decimal, default: 0.0
      add :total_gastado, :decimal, default: 0.0
      add :total_ganado, :decimal, default: 0.0
    end
  end
end