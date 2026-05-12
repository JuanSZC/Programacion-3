defmodule AzarApp.Repo.Migrations.CambiarPremioFijoADecimal do
  use Ecto.Migration

  def change do
    alter table(:sorteos) do
      # precision: 15 (dígitos totales), scale: 2 (decimales)
      modify :premio_fijo, :decimal, precision: 15, scale: 2
    end
  end
end
