defmodule AzarApp.Cuentas do
  @moduledoc """
  Contexto para el manejo de Usuarios y Autenticación.
  """

  alias AzarApp.Repo
  alias AzarApp.Cuentas.Usuario

  # --- AUTENTICACIÓN ---

  def autenticar_usuario(email, password) do
    usuario = obtener_usuario_por_email(email)

    # CORRECCIÓN: Usamos Pbkdf2.verify_pass para comparar la clave plana con el hash
    if usuario && Pbkdf2.verify_pass(password, usuario.password_hash) do
      case actualizar_ultimo_login(usuario) do
        {:ok, usuario_actualizado} -> {:ok, usuario_actualizado}
        {:error, _} -> {:ok, usuario}
      end
    else
      # Pbkdf2.no_user_verify() ayuda a prevenir ataques de enumeración de usuarios
      Pbkdf2.no_user_verify()
      {:error, "Correo o contraseña inválidos"}
    end
  end

  defp actualizar_ultimo_login(usuario) do
    usuario
    # Usamos un changeset específico para esto o permitimos el cambio en el de update
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

  # --- LÓGICA DE DINERO (PROYECTO AZAR S.A.) ---

  @doc """
  Recarga el saldo virtual del usuario.
  Útil para la simulación de tarjeta de crédito.
  """
  def recargar_saldo(usuario, monto) do
    # Usamos Decimal.add para precisión financiera
    monto_decimal = Decimal.new("#{monto}")
    nuevo_saldo = Decimal.add(usuario.saldo_virtual || Decimal.new("0"), monto_decimal)

    usuario
    |> Ecto.Changeset.cast(%{saldo_virtual: nuevo_saldo}, [:saldo_virtual])
    |> Repo.update()
  end

  @doc """
  Calcula el balance personal del usuario.
  Pág 3 del PDF: Diferencia entre dinero gastado y premios obtenidos.
  """
def obtener_balance_personal(_usuario_id) do
    # Aquí luego sumaremos los tickets comprados y los premios ganados
    # Por ahora devolvemos un mapa base
    %{
      gastado: Decimal.new("0.00"),
      premios: Decimal.new("0.00"),
      balance: Decimal.new("0.00")
    }
  end


def change_usuario(%Usuario{} = usuario, attrs \\ %{}) do
  Usuario.update_changeset(usuario, attrs)
end

def update_usuario(%Usuario{} = usuario, attrs) do
  usuario
  |> Usuario.update_changeset(attrs)
  |> Repo.update()
end

def actualizar_usuario_nombre(usuario, nuevo_nombre) do
  usuario
  |> Ecto.Changeset.change(%{nombre: nuevo_nombre})
  |> Repo.update()
end

def actualizar_campo_usuario(usuario, campo, valor) do
  changeset = case campo do
    "nombre" -> Ecto.Changeset.change(usuario, %{nombre: valor})
    "email"  -> Ecto.Changeset.change(usuario, %{email: valor})
    "password" ->
      # Usamos Pbkdf2 para encriptar la nueva contraseña
      hash = Pbkdf2.hash_pwd_salt(valor)
      Ecto.Changeset.change(usuario, %{password_hash: hash})
    _ -> Ecto.Changeset.change(usuario, %{})
  end

  Repo.update(changeset)
end
end
