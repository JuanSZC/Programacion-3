# priv/repo/migrations/XXXXXX_create_transacciones.exs
defmodule AzarApp.Repo.Migrations.CreateTransacciones do
  use Ecto.Migration

  def change do
    create table(:transacciones) do
      add :usuario_id, references(:usuarios, on_delete: :delete_all), null: false
      add :tipo, :string, null: false
      # "recarga" | "compra_ticket" | "devolucion_ticket" | "premio"
      add :monto, :decimal, null: false
      add :descripcion, :string
      add :sorteo_id, references(:sorteos, on_delete: :nilify_all)
      add :ticket_numero, :string

      timestamps(type: :utc_datetime)
    end

    create index(:transacciones, [:usuario_id])
    create index(:transacciones, [:sorteo_id])
  end
end
