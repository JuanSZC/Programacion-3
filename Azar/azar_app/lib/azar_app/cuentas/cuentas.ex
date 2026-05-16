defmodule AzarApp.Cuentas do
  @moduledoc """
  Contexto principal para el manejo de Cuentas, Usuarios y Autenticación.

  Se encarga de la gestión del ciclo de vida del usuario (creación, actualización,
  eliminación), autenticación, y toda la lógica financiera relacionada con los
  saldos virtuales, recargas y estadísticas de juego.
  """

  alias AzarApp.Repo
  alias AzarApp.Cuentas.Usuario
  import Ecto.Query, warn: false

  # ==========================================
  # AUTENTICACIÓN
  # ==========================================

  @doc """
  Verifica las credenciales de un usuario.
  Si son correctas, actualiza su último login y devuelve `{:ok, usuario}`.
  Si fallan, devuelve un error seguro.
  """
  def autenticar_usuario(email, password) do
    usuario = obtener_usuario_por_email(email)

    if usuario && Pbkdf2.verify_pass(password, usuario.password_hash) do
      case actualizar_ultimo_login(usuario) do
        {:ok, usuario_actualizado} -> {:ok, usuario_actualizado}
        {:error, _} -> {:ok, usuario}
      end
    else
      # Previene ataques de timing (enumeración de usuarios)
      Pbkdf2.no_user_verify()
      {:error, "Correo o contraseña inválidos"}
    end
  end

  defp actualizar_ultimo_login(usuario) do
    usuario
    |> Ecto.Changeset.cast(%{ultimo_login: NaiveDateTime.utc_now()}, [:ultimo_login])
    |> Repo.update()
  end

  # ==========================================
  # CONSULTAS DE LECTURA
  # ==========================================

  @doc "Obtiene un usuario por su ID, devuelve nil si no existe."
  def obtener_usuario(id), do: Repo.get(Usuario, id)

  @doc "Obtiene un usuario por su ID, lanza un error si no existe."
  def obtener_usuario!(id), do: Repo.get!(Usuario, id)

  @doc "Busca un usuario por su correo electrónico (case-insensitive)."
  def obtener_usuario_por_email(email) do
    Repo.get_by(Usuario, email: String.downcase(email || ""))
  end

  @doc "Devuelve absolutamente todos los usuarios de la base de datos (Admin y Clientes)."
  def listar_usuarios, do: Repo.all(Usuario)

  @doc "Devuelve únicamente los usuarios con rol 'cliente', ordenados por fecha de creación descendente."
  def list_usuarios do
    query = from(u in Usuario, where: u.rol == "cliente", order_by: [desc: u.inserted_at])
    Repo.all(query)
  end

  @doc """
  Busca clientes usando un término de búsqueda.
  Coincide parcialmente con nombre, email o cédula.
  """
  def buscar_usuarios(query) do
    q = "%#{String.downcase(query)}%"

    sql = from(u in Usuario,
      where: u.rol == "cliente" and
        (ilike(u.nombre, ^q) or ilike(u.email, ^q) or ilike(u.cedula, ^q)),
      order_by: [desc: u.inserted_at]
    )

    Repo.all(sql)
  end

  # ==========================================
  # GESTIÓN DE USUARIOS (ACCIONES)
  # ==========================================

  @doc "Crea un nuevo usuario usando el changeset de registro."
  def crear_usuario(attrs \\ %{}) do
    %Usuario{}
    |> Usuario.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc "Actualiza un usuario con los parámetros generales (perfil)."
  def actualizar_usuario(%Usuario{} = usuario, attrs) do
    usuario
    |> Usuario.update_changeset(attrs)
    |> Repo.update()
  end

  @doc "Actualiza un usuario usando el changeset de administrador (permite saltar validaciones estrictas)."
  def actualizar_usuario_admin(%Usuario{} = usuario, params) do
    usuario
    |> Usuario.changeset_admin(params)
    |> Repo.update()
  end

  @doc "Devuelve un changeset para un usuario (útil para formularios)."
  def change_usuario(%Usuario{} = usuario, attrs \\ %{}) do
    Usuario.update_changeset(usuario, attrs)
  end

  @doc "Actualiza un único campo específico del usuario (nombre, email, o password)."
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

  @doc "Activa o inactiva un usuario (Toggle)."
  def toggle_activo(%Usuario{} = usuario) do
    usuario
    |> Ecto.Changeset.change(activo: !usuario.activo)
    |> Repo.update()
  end

  @doc """
  Verifica si un usuario tiene tickets comprados en sorteos que aún están activos.
  """
  def tiene_tickets_activos?(usuario_id) do
    query = from(t in AzarApp.Sorteos.Ticket,
      join: s in AzarApp.Sorteos.Sorteo, on: t.sorteo_id == s.id,
      where: t.usuario_id == ^usuario_id and s.estado == "activo" and t.estado == "vendido"
    )

    Repo.exists?(query)
  end

  @doc """
  Elimina un usuario de forma segura.
  Impide la eliminación si el usuario tiene tickets en sorteos activos.
  """
  def eliminar_usuario(%Usuario{} = usuario) do
    if tiene_tickets_activos?(usuario.id) do
      {:error, "No se puede eliminar el usuario porque tiene tickets en sorteos activos."}
    else
      Repo.delete(usuario)
    end
  end

  # ==========================================
  # LÓGICA DE DINERO Y FINANZAS
  # ==========================================

  @doc "Añade saldo a un usuario y suma al total histórico recargado."
  def recargar_saldo(usuario, monto) do
    monto_decimal = Decimal.new("#{monto}")

    nuevo_saldo = Decimal.add(usuario.saldo_virtual || Decimal.new(0), monto_decimal)
    nuevo_total_recargado = Decimal.add(usuario.total_recargado || Decimal.new(0), monto_decimal)

    usuario
    |> Ecto.Changeset.cast(%{
      saldo_virtual: nuevo_saldo,
      total_recargado: nuevo_total_recargado
    }, [:saldo_virtual, :total_recargado])
    |> Repo.update()
  end

  @doc "Añade saldo por un premio ganado y suma al total histórico ganado."
  def registrar_premio(usuario, monto) do
    monto_decimal = Decimal.new("#{monto}")

    usuario
    |> Ecto.Changeset.cast(%{
      saldo_virtual: Decimal.add(usuario.saldo_virtual || Decimal.new(0), monto_decimal),
      total_ganado: Decimal.add(usuario.total_ganado || Decimal.new(0), monto_decimal)
    }, [:saldo_virtual, :total_ganado])
    |> Repo.update()
  end

  @doc "Ajuste manual de saldo desde el panel de administrador (puede ser suma o resta)."
  def ajustar_saldo_admin(%Usuario{} = usuario, monto) do
    nuevo = Decimal.add(usuario.saldo_virtual || Decimal.new(0), Decimal.new("#{monto}"))

    usuario
    |> Ecto.Changeset.change(saldo_virtual: nuevo)
    |> Repo.update()
  end

  @doc """
  Calcula el balance financiero integral y las estadísticas de juego de un usuario.
  Obtiene dinámicamente los datos de tickets comprados y premios ganados cruzando la BD.
  """
  def obtener_balance_personal(%Usuario{} = usuario) do
    # Total gastado = suma de precio_ticket de todos sus tickets comprados
    gastado =
      Repo.one(
        from t in AzarApp.Sorteos.Ticket,
          join: s in AzarApp.Sorteos.Sorteo, on: t.sorteo_id == s.id,
          where: t.usuario_id == ^usuario.id and t.estado == "vendido",
          select: coalesce(sum(s.precio_ticket), 0)
      ) || Decimal.new(0)

    # Total ganado = precio_ticket de tickets ganadores (o premio_fijo si aplica)
    ganado =
      Repo.one(
        from t in AzarApp.Sorteos.Ticket,
          join: s in AzarApp.Sorteos.Sorteo, on: t.sorteo_id == s.id,
          where:
            t.usuario_id == ^usuario.id and
            t.estado == "vendido" and
            s.estado == "finalizado" and
            fragment("? = ANY(?)", t.numero, s.numeros_ganadores),
          select: coalesce(sum(
            fragment("CASE WHEN ? = 'fijo' THEN ? ELSE ? END",
              s.tipo_premio, s.premio_fijo, s.precio_ticket)
          ), 0)
      ) || Decimal.new(0)

    recargado = usuario.total_recargado || Decimal.new(0)
    saldo = usuario.saldo_virtual || Decimal.new(0)

    # Rendimiento neto de juego (ganado - gastado)
    rendimiento = Decimal.sub(ganado, gastado)

    # Estadísticas de participación
    tickets_count =
      Repo.one(
        from t in AzarApp.Sorteos.Ticket,
          where: t.usuario_id == ^usuario.id and t.estado == "vendido",
          select: count(t.id)
      ) || 0

    sorteos_count =
      Repo.one(
        from t in AzarApp.Sorteos.Ticket,
          where: t.usuario_id == ^usuario.id and t.estado == "vendido",
          select: count(t.sorteo_id, :distinct)
      ) || 0

    %{
      gastado: gastado,
      ganado: ganado,
      recargado: recargado,
      saldo: saldo,
      rendimiento: rendimiento,
      tickets: tickets_count,
      sorteos: sorteos_count,
      es_ganancia: Decimal.compare(rendimiento, 0) != :lt
    }
  end

end
