defmodule AzarApp.Cuentas.Usuario do
  use Ecto.Schema
  import Ecto.Changeset

  schema "usuarios" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :rol, :string, default: "cliente"
    field :nombre, :string
    field :cedula, :string
    field :edad, :integer
    field :activo, :boolean, default: true
    field :ultimo_login, :naive_datetime
    field :saldo_virtual, :decimal, default: 0.0

    field :total_recargado, :decimal, default: 0.0
    field :total_gastado, :decimal, default: 0.0
    field :total_ganado, :decimal, default: 0.0

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(usuario, attrs) do
    usuario
    |> cast(attrs, [:email, :password, :nombre, :cedula, :edad, :rol, :saldo_virtual, :total_recargado, :total_gastado, :total_ganado])
    |> validate_required([:email, :password, :nombre])
    |> validate_email()
    |> validate_length(:password, min: 8, max: 128)
    |> unique_constraint(:email)
    |> hash_password()
  end

  def update_changeset(usuario, attrs) do
    usuario
    |> cast(attrs, [:nombre, :edad, :cedula, :activo, :ultimo_login, :saldo_virtual, :total_recargado, :total_gastado, :total_ganado])
    |> validate_length(:nombre, min: 2, max: 100)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "Correo inválido")
  end

  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(password))
  end
  defp hash_password(changeset), do: changeset
end
