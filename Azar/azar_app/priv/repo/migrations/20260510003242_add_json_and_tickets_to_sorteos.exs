defmodule AzarApp.Repo.Migrations.AddJsonAndTicketsToSorteos do
  use Ecto.Migration

  def change do
    # 1. Añadimos el campo JSON a la tabla de sorteos existente
    alter table(:sorteos) do
      add :configuracion, :map, default: %{}
    end

    # 2. Creamos la tabla de tickets para que el admin pueda generar números
    create table(:tickets) do
      add :numero, :string, null: false
      add :estado, :string, default: "disponible" # disponible, apartado, pagado
      add :sorteo_id, references(:sorteos, on_delete: :delete_all)
      add :usuario_id, references(:usuarios, on_delete: :nilify_all) # Quien lo compra

      timestamps(type: :utc_datetime)
    end

    create index(:tickets, [:sorteo_id])
    create index(:tickets, [:usuario_id])
    create index(:tickets, [:numero, :sorteo_id], unique: true)
  end
end
