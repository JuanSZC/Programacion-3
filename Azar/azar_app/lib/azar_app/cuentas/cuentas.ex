defmodule AzarApp.Cuentas do
  @moduledoc """
  Contexto para el manejo de Usuarios y Autenticación.
  """

  alias AzarApp.Repo
  alias AzarApp.Cuentas.Usuario

  # --- AUTENTICACIÓN ---

  def autenticar_usuario(email, password) do
    usuario = obtener_usuario_por_email(email)

    if usuario && Pbkdf2.verify_pass(password, usuario.password_hash) do
      case actualizar_ultimo_login(usuario) do
        {:ok, usuario_actualizado} -> {:ok, usuario_actualizado}
        {:error, _} -> {:ok, usuario}
      end
    else
      Pbkdf2.no_user_verify()
      {:error, "Correo o contraseña inválidos"}
    end
  end

  defp actualizar_ultimo_login(usuario) do
    usuario
    |> Ecto.Changeset.cast(%{ultimo_login: NaiveDateTime.utc_now()}, [:ultimo_login])
    |> Repo.update()
  end

  # --- CONSULTAS ---

  def obtener_usuario(id), do: Repo.get(Usuario, id)
  def obtener_usuario!(id), do: Repo.get!(Usuario, id)

  def obtener_usuario_por_email(email) do
    Repo.get_by(Usuario, email: String.downcase(email || ""))
  end

  def listar_usuarios, do: Repo.all(Usuario)

  # --- ACCIONES ---

  def crear_usuario(attrs \\ %{}) do
    %Usuario{}
    |> Usuario.registration_changeset(attrs)
    |> Repo.insert()
  end

  def actualizar_usuario(usuario, attrs) do
    usuario
    |> Usuario.update_changeset(attrs)
    |> Repo.update()
  end

  def eliminar_usuario(usuario), do: Repo.delete(usuario)

  # --- LÓGICA DE DINERO ---

  def recargar_saldo(usuario, monto) do
    monto_decimal = Decimal.new("#{monto}")

    nuevo_saldo = Decimal.add(usuario.saldo_virtual || Decimal.new("0"), monto_decimal)
    nuevo_total_recargado = Decimal.add(usuario.total_recargado || Decimal.new("0"), monto_decimal)

    usuario
    |> Ecto.Changeset.cast(%{
      saldo_virtual: nuevo_saldo,
      total_recargado: nuevo_total_recargado
    }, [:saldo_virtual, :total_recargado])
    |> Repo.update()
  end

  def registrar_premio(usuario, monto) do
    monto_decimal = Decimal.new("#{monto}")

    usuario
    |> Ecto.Changeset.cast(%{
      saldo_virtual: Decimal.add(usuario.saldo_virtual || Decimal.new("0"), monto_decimal),
      total_ganado: Decimal.add(usuario.total_ganado || Decimal.new("0"), monto_decimal)
    }, [:saldo_virtual, :total_ganado])
    |> Repo.update()
  end

  def obtener_balance_personal(usuario) do
    gastado = usuario.total_gastado || Decimal.new("0")
    premios = usuario.total_ganado || Decimal.new("0")
    balance = Decimal.sub(premios, gastado)

    %{
      gastado: gastado,
      premios: premios,
      balance: balance
    }
  end

  def change_usuario(%Usuario{} = usuario, attrs \\ %{}) do
    Usuario.update_changeset(usuario, attrs)
  end

  def actualizar_campo_usuario(usuario, campo, valor) do
    changeset = case campo do
      "nombre" -> Ecto.Changeset.change(usuario, %{nombre: valor})
      "email"  -> Ecto.Changeset.change(usuario, %{email: valor})
      "password" ->
        hash = Pbkdf2.hash_pwd_salt(valor)
        Ecto.Changeset.change(usuario, %{password_hash: hash})
      _ -> Ecto.Changeset.change(usuario, %{})
    end
    Repo.update(changeset)
  end
end
