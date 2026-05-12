defmodule AzarApp.Repo.Migrations.AddFieldsToSorteos do
  use Ecto.Migration

  def change do
    alter table(:sorteos) do
      add :cantidad_ganadores, :integer, default: 1
      add :total_tickets, :integer, default: 100
    end
  end
end
