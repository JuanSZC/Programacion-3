defmodule AzarApp.Repo.Migrations.CreateNotificaciones do
  use Ecto.Migration

  def change do
    create table(:notificaciones) do
      add :usuario_id, references(:usuarios, on_delete: :delete_all), null: false
      add :sorteo_id, references(:sorteos, on_delete: :delete_all), null: false
      add :ticket_numero, :string, null: false
      add :monto_premio, :decimal, null: false
      add :tipo_premio, :string, null: false
      add :leida, :boolean, default: false, null: false

      timestamps()
    end

    create index(:notificaciones, [:usuario_id])
    create index(:notificaciones, [:usuario_id, :leida])
  end
end
