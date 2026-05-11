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
    # --- AGREGAR ESTA LÍNEA ---
    field :saldo_virtual, :decimal, default: 0.0

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(usuario, attrs) do
    usuario
    # Agregamos :saldo_virtual al cast
    |> cast(attrs, [:email, :password, :nombre, :cedula, :edad, :rol, :saldo_virtual])
    |> validate_required([:email, :password, :nombre])
    |> validate_email()
    |> validate_length(:password, min: 8, max: 128)
    |> unique_constraint(:email, message: "El correo ya está registrado")
    |> hash_password()
  end

  def update_changeset(usuario, attrs) do
    usuario
    # Agregamos :saldo_virtual aquí también para poder actualizarlo
    |> cast(attrs, [:nombre, :edad, :cedula, :activo, :ultimo_login, :saldo_virtual])
    |> validate_length(:nombre, min: 2, max: 100)
  end


  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "Correo inválido")
    |> update_change(:email, &String.downcase/1)
  end

  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    changeset
    |> put_change(:password_hash, Pbkdf2.hash_pwd_salt(password))
    |> delete_change(:password)
  end
  defp hash_password(changeset), do: changeset
end
