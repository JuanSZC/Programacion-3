defmodule AzarApp.Repo.Migrations.CreateSorteos do
  use Ecto.Migration

  def change do
    create table(:sorteos) do
      add :titulo, :string
      add :descripcion, :text
      add :fecha_sorteo, :naive_datetime
      add :precio_ticket, :decimal
      add :estado, :string
      add :imagen_url, :string

      timestamps(type: :utc_datetime)
    end
  end
end
