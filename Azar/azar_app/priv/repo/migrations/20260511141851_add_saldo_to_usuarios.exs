defmodule AzarApp.Repo.Migrations.AddSaldoToUsuarios do
  use Ecto.Migration

  def change do
    alter table(:usuarios) do
      # Solo añadimos el saldo y el avatar que son los que faltan
      add :saldo_virtual, :decimal, default: 0.0, precision: 15, scale: 2
      add :avatar_url, :string
    end
  end
end
