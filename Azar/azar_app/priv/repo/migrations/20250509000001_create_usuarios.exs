defmodule AzarApp.Repo.Migrations.CreateUsuarios do
  use Ecto.Migration

  def change do
    create table(:usuarios) do
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :rol, :string, null: false, default: "cliente"
      add :nombre, :string, null: false
      add :cedula, :string
      add :edad, :integer
      add :activo, :boolean, default: true
      add :ultimo_login, :naive_datetime

      # ¡Aquí estaba el error! Cambiamos :utc_datetime_ms por :utc_datetime
      timestamps(type: :utc_datetime)
    end

    create unique_index(:usuarios, [:email])
    create index(:usuarios, [:cedula])
    create index(:usuarios, [:rol])
  end
end
