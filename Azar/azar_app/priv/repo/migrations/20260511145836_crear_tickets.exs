defmodule AzarApp.Repo.Migrations.CrearTickets do
  use Ecto.Migration

  def change do
    # Solo crea la tabla si no existe
    execute "CREATE TABLE IF NOT EXISTS tickets (
      id SERIAL PRIMARY KEY,
      numero INTEGER,
      usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
      sorteo_id INTEGER REFERENCES sorteos(id) ON DELETE CASCADE,
      inserted_at TIMESTAMP NOT NULL,
      updated_at TIMESTAMP NOT NULL
    )"

    # Esto evitará el error de "la relación tickets ya existe"
    create_if_not_exists unique_index(:tickets, [:numero, :sorteo_id])
  end
end
