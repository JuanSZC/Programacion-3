defmodule AzarApp.Repo.Migrations.AddTiposYGanadoresASorteos do
  use Ecto.Migration

  def change do
    alter table(:sorteos) do
      add :tipo_premio, :string, default: "fijo", null: false
      add :premio_fijo, :integer
      add :porcentaje_casa, :integer, default: 30
      add :numeros_ganadores, {:array, :string}, default: []

      # Eliminamos la línea de :estado porque ya existe en tu tabla
    end
  end
end
