defmodule AzarApp.Repo.Migrations.ActualizarCamposSorteos do
  use Ecto.Migration

  def change do
    alter table(:sorteos) do
      # Comentamos TODO lo que ya falló por "duplicate_column"
      # add :descripcion, :text
      # add :total_tickets, :integer
      # add :cantidad_ganadores, :integer
      # add :precio_ticket, :decimal

      # Solo dejamos esta, que es la última que falta:
      add :fecha_ejecucion, :utc_datetime
    end
  end
end
