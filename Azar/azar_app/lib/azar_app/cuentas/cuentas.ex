defmodule AzarApp.Cuentas do
  @moduledoc false

  alias AzarApp.Repo
  alias AzarApp.Cuentas.Usuario
  import Ecto.Query, warn: false

  @limite_max_ajuste Decimal.new(10_000_000)


  @doc """
  Breve: autenticar_usuario.
  """
  def autenticar_usuario(email, password) do
    usuario = obtener_usuario_por_email(email)

    if usuario && Pbkdf2.verify_pass(password, usuario.password_hash) do
      case actualizar_ultimo_login(usuario) do
        {:ok, usuario_actualizado} -> {:ok, usuario_actualizado}
        {:error, _} -> {:ok, usuario}
      end
    else
      Pbkdf2.no_user_verify() # Previene enumeración de usuarios
      {:error, "Correo o contraseña inválidos"}
    end
  end

  defp actualizar_ultimo_login(usuario) do
    usuario
    |> Ecto.Changeset.cast(%{ultimo_login: NaiveDateTime.utc_now()}, [:ultimo_login])
    |> Repo.update()
  end


  @doc """
  Breve: obtener_usuario.
  """
  def obtener_usuario(id) do
    case Repo.get(Usuario, id) do
      nil -> {:error, :not_found}
      usuario -> {:ok, usuario}
    end
  end

  @doc """
  Breve: obtener_usuario.
  """
  def obtener_usuario!(id), do: Repo.get!(Usuario, id)

  @doc """
  Breve: obtener_usuario_por_email.
  """
  def obtener_usuario_por_email(email) do
    Repo.get_by(Usuario, email: String.downcase(email || ""))
  end

  @doc """
  Breve: listar_usuarios.
  """
  def listar_usuarios, do: Repo.all(Usuario)

  @doc """
  Breve: list_usuarios.
  """
  def list_usuarios do
    from(u in Usuario, where: u.rol == "cliente", order_by: [desc: u.inserted_at])
    |> Repo.all()
  end

  @doc """
  Breve: buscar_usuarios.
  """
  def buscar_usuarios(query) do
    q = "%#{String.downcase(query)}%"

    from(u in Usuario,
      where: u.rol == "cliente" and
        (ilike(u.nombre, ^q) or ilike(u.email, ^q) or ilike(u.cedula, ^q)),
      order_by: [desc: u.inserted_at]
    )
    |> Repo.all()
  end


 @doc """
 Breve: crear_usuario.
 """
 def crear_usuario(attrs \\ %{}) do
  case %Usuario{}
       |> Usuario.registration_changeset(attrs)
       |> Repo.insert() do

    {:ok, usuario} ->
      AzarApp.Auditoria.log(:usuario_creado, %{
        usuario_id: usuario.id,
        email: usuario.email,
        rol: usuario.rol
      })

      {:ok, usuario}

    error ->
      error
  end
end

  @doc """
  Breve: actualizar_usuario.
  """
  def actualizar_usuario(%Usuario{} = usuario, attrs) do
    usuario
    |> Usuario.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Breve: actualizar_usuario_admin.
  """
  def actualizar_usuario_admin(%Usuario{} = usuario, params) do
    usuario
    |> Usuario.changeset_admin(params)
    |> Repo.update()
  end

  @doc """
  Breve: change_usuario.
  """
  def change_usuario(%Usuario{} = usuario, attrs \\ %{}) do
    Usuario.update_changeset(usuario, attrs)
  end

  @doc """
  Breve: actualizar_campo_usuario.
  """
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

  @doc """
  Breve: toggle_activo.
  """
  def toggle_activo(%Usuario{} = usuario) do
    if usuario.rol == "admin" && usuario.activo do
      admins_activos = Repo.one(from u in Usuario, where: u.rol == "admin" and u.activo == true, select: count(u.id))

      if admins_activos <= 1 do
        {:error, "No puedes desactivar al único administrador activo"}
      else
        do_toggle(usuario)
      end
    else
      do_toggle(usuario)
    end
  end

defp do_toggle(usuario) do
  case usuario
       |> Ecto.Changeset.change(activo: !usuario.activo)
       |> Repo.update() do

    {:ok, usuario_actualizado} ->

      AzarApp.Auditoria.log(
        if(usuario_actualizado.activo,
          do: :usuario_activado,
          else: :usuario_desactivado
        ),
        %{
          usuario_id: usuario_actualizado.id
        }
      )

      {:ok, usuario_actualizado}

    error ->
      error
  end
end

  @doc """
  Breve: tiene_tickets_activos.
  """
  def tiene_tickets_activos?(usuario_id) do
    query = from(t in AzarApp.Sorteos.Ticket,
      join: s in AzarApp.Sorteos.Sorteo, on: t.sorteo_id == s.id,
      where: t.usuario_id == ^usuario_id and s.estado == "activo" and t.estado == "vendido"
    )
    Repo.exists?(query)
  end

  @doc """
  Breve: eliminar_usuario.
  """
  def eliminar_usuario(%Usuario{} = usuario) do
    cond do
      usuario.rol == "admin" ->
        {:error, "No se puede eliminar una cuenta de administrador"}
      tiene_tickets_activos?(usuario.id) ->
        {:error, "El usuario tiene tickets en sorteos activos"}
      true ->

  AzarApp.Auditoria.log(:usuario_eliminado, %{
    usuario_id: usuario.id,
    email: usuario.email
  })

  Repo.delete(usuario)
    end
  end


@doc """
Breve: recargar_saldo.
"""
def recargar_saldo(usuario, monto) do
  monto_d = decimal_seguro(monto)
  nuevo_saldo = Decimal.add(decimal_seguro(usuario.saldo_virtual), monto_d)
  nuevo_recargado = Decimal.add(decimal_seguro(usuario.total_recargado), monto_d)

  Ecto.Multi.new()
  |> Ecto.Multi.update(:usuario, Usuario.update_changeset(usuario, %{
      saldo_virtual: nuevo_saldo,
      total_recargado: nuevo_recargado
    }))
|> Ecto.Multi.insert(:transaccion,
    AzarApp.Cuentas.Transaccion.changeset(%AzarApp.Cuentas.Transaccion{}, %{
      usuario_id: usuario.id,
      tipo: "recarga",
      monto: monto_d,
      descripcion: "Recarga de saldo"
    })
  )
  |> Repo.transaction()
  |> case do
    {:ok, %{usuario: u}} ->

  AzarApp.Auditoria.log(:recarga_saldo, %{
    usuario_id: u.id,
    monto: monto_d,
    metodo: "plataforma"
  })

  {:ok, u}
    {:error, _, changeset, _} -> {:error, changeset}
  end
end

@doc """
Breve: registrar_premio.
"""
def registrar_premio(usuario, monto, sorteo_id \\ nil) do
  monto_d = decimal_seguro(monto)
  nuevo_saldo = Decimal.add(decimal_seguro(usuario.saldo_virtual), monto_d)
  nuevo_ganado = Decimal.add(decimal_seguro(usuario.total_ganado), monto_d)

  Ecto.Multi.new()
  |> Ecto.Multi.update(:usuario, Usuario.update_changeset(usuario, %{
      saldo_virtual: nuevo_saldo,
      total_ganado: nuevo_ganado
    }))
  |> Ecto.Multi.insert(:transaccion,
    AzarApp.Cuentas.Transaccion.changeset(%AzarApp.Cuentas.Transaccion{}, %{
      usuario_id: usuario.id,
      tipo: "premio",
      monto: monto_d,
      descripcion: "Premio ganado",
      sorteo_id: sorteo_id
    })
  )
  |> Repo.transaction()
  |> case do
    {:ok, %{usuario: u}} -> {:ok, u}
    {:error, _, changeset, _} -> {:error, changeset}
  end
end

  @doc """
  Breve: ajustar_saldo_admin.
  """
  def ajustar_saldo_admin(%Usuario{} = usuario, monto) do
    try do
      monto_limpio =
        "#{monto}"
        |> String.trim()
        |> String.replace(",", ".")          # "1,500" → "1.500"
        |> String.replace(~r/[^\d.\-]/, "")  # elimina cualquier otro carácter extraño

      if monto_limpio == "" or monto_limpio == "-" do
        raise ArgumentError, "vacío"
      end

      monto_decimal = Decimal.new(monto_limpio)
      monto_absoluto = Decimal.abs(monto_decimal)
      saldo_actual = usuario.saldo_virtual || Decimal.new(0)
      nuevo_saldo = Decimal.add(saldo_actual, monto_decimal)

      cond do
        Decimal.equal?(monto_decimal, Decimal.new(0)) ->
          {:error, "El monto de ajuste no puede ser cero ($0)"}

        Decimal.gt?(monto_absoluto, @limite_max_ajuste) ->
          {:error, "Monto inválido. El ajuste máximo permitido es de $#{@limite_max_ajuste}"}

        Decimal.lt?(nuevo_saldo, Decimal.new(0)) ->
          {:error, "El saldo no puede quedar negativo (Saldo actual: $#{saldo_actual})"}

        true ->

  case usuario
       |> Ecto.Changeset.change(saldo_virtual: nuevo_saldo)
       |> Repo.update() do

    {:ok, usuario_actualizado} ->

      AzarApp.Auditoria.log(:saldo_ajustado_admin, %{
        usuario_id: usuario.id,
        monto: monto_decimal,
        operacion:
          if(Decimal.negative?(monto_decimal),
            do: "restar",
            else: "sumar"
          ),
        admin_id: "admin"
      })

      {:ok, usuario_actualizado}

    error ->
      error
  end
      end
    rescue
      _ -> {:error, "El valor ingresado no es un número válido"}
    end
  end

  @doc """
  Breve: vaciar_cuenta_admin.
  """
  def vaciar_cuenta_admin(%Usuario{} = usuario) do
    saldo_actual = usuario.saldo_virtual || Decimal.new(0)

    cond do
      Decimal.equal?(saldo_actual, Decimal.new(0)) ->
        {:error, "La cuenta ya está en $0, no hay nada que vaciar"}

      true ->

  case usuario
       |> Ecto.Changeset.change(saldo_virtual: Decimal.new(0))
       |> Repo.update() do

    {:ok, usuario_actualizado} ->

      AzarApp.Auditoria.log(:cuenta_vaciada_admin, %{
        usuario_id: usuario_actualizado.id,
        admin_id: "admin"
      })

      {:ok, usuario_actualizado}

    error ->
      error
  end
    end
  end

  @doc """
  Breve: obtener_balance_personal.
  """
  def obtener_balance_personal(%Usuario{} = usuario) do
    gastado = Repo.one(
      from t in AzarApp.Sorteos.Ticket,
        join: s in AzarApp.Sorteos.Sorteo, on: t.sorteo_id == s.id,
        where: t.usuario_id == ^usuario.id and t.estado == "vendido",
        select: coalesce(sum(s.precio_ticket), 0)
    ) || Decimal.new(0)

    ganado = Repo.one(
      from t in AzarApp.Sorteos.Ticket,
        join: s in AzarApp.Sorteos.Sorteo, on: t.sorteo_id == s.id,
        where: t.usuario_id == ^usuario.id and
               t.estado == "vendido" and
               s.estado == "finalizado" and
               fragment("? = ANY(?)", t.numero, s.numeros_ganadores),
        select: coalesce(sum(
          fragment("CASE WHEN ? = 'fijo' THEN ? ELSE ? END", s.tipo_premio, s.premio_fijo, s.precio_ticket)
        ), 0)
    ) || Decimal.new(0)

    recargado = usuario.total_recargado || Decimal.new(0)
    saldo = usuario.saldo_virtual || Decimal.new(0)
    rendimiento = Decimal.sub(ganado, gastado)

    tickets_count = Repo.one(from t in AzarApp.Sorteos.Ticket, where: t.usuario_id == ^usuario.id and t.estado == "vendido", select: count(t.id)) || 0
    sorteos_count = Repo.one(from t in AzarApp.Sorteos.Ticket, where: t.usuario_id == ^usuario.id and t.estado == "vendido", select: count(t.sorteo_id, :distinct)) || 0

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

  @doc """
  Breve: registrar_compra_ticket.
  """
  def registrar_compra_ticket(usuario_id, sorteo_id, numero, monto) do
  %AzarApp.Cuentas.Transaccion{}
  |> AzarApp.Cuentas.Transaccion.changeset(%{
      usuario_id: usuario_id,
      tipo: "compra_ticket",
      monto: decimal_seguro(monto),
      descripcion: "Compra ticket ##{numero}",
      sorteo_id: sorteo_id,
      ticket_numero: to_string(numero)
    })
  |> Repo.insert()
end

@doc """
Breve: registrar_devolucion_ticket.
"""
def registrar_devolucion_ticket(usuario_id, sorteo_id, numero, monto) do
  %AzarApp.Cuentas.Transaccion{}
  |> AzarApp.Cuentas.Transaccion.changeset(%{
      usuario_id: usuario_id,
      tipo: "devolucion_ticket",
      monto: decimal_seguro(monto),
      descripcion: "Devolución ticket ##{numero}",
      sorteo_id: sorteo_id,
      ticket_numero: to_string(numero)
    })
  |> Repo.insert()
end

@doc """
Breve: listar_transacciones.
"""
def listar_transacciones(usuario_id) do
  Repo.all(
    from t in AzarApp.Cuentas.Transaccion,
    where: t.usuario_id == ^usuario_id,
    order_by: [desc: t.inserted_at],
    preload: [:sorteo]
  )
end

defp decimal_seguro(nil), do: Decimal.new(0)
defp decimal_seguro(%Decimal{} = v), do: v
defp decimal_seguro(v), do: Decimal.new(to_string(v))


@doc """
Breve: limpiar_sistema_completo.
"""
def limpiar_sistema_completo() do
  emails_protegidos = ["admin@azar.com", "cliente@azar.com"]

  Ecto.Multi.new()
  |> Ecto.Multi.delete_all(:transacciones,
      from(t in AzarApp.Cuentas.Transaccion, select: t))
  |> Ecto.Multi.delete_all(:tickets,
      from(t in AzarApp.Sorteos.Ticket, select: t))
  |> Ecto.Multi.delete_all(:sorteos,
      from(s in AzarApp.Sorteos.Sorteo, select: s))
  |> Ecto.Multi.delete_all(:usuarios,
      from(u in AzarApp.Cuentas.Usuario,
        where: u.email not in ^emails_protegidos,
        select: u))
  |> Ecto.Multi.update_all(:reset_usuarios,
      from(u in AzarApp.Cuentas.Usuario,
        where: u.email in ^emails_protegidos),
      set: [
        saldo_virtual: Decimal.new("0"),
        total_recargado: Decimal.new("0"),
        total_gastado: Decimal.new("0"),
        total_ganado: Decimal.new("0")
      ])
  |> Repo.transaction()
  |> case do
    {:ok, resultado} ->
      File.rm("log/auditoria.log")

      AzarApp.Backup.limpiar_todo()

      AzarApp.Auditoria.log(:sistema_limpiado, %{
        tickets: resultado.tickets |> elem(0),
        sorteos: resultado.sorteos |> elem(0),
        usuarios: resultado.usuarios |> elem(0)
      })

      {:ok, resultado}

    {:error, op, razon, _} ->
      {:error, "Falló en #{op}: #{inspect(razon)}"}
  end
end
end
