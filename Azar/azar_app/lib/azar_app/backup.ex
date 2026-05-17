defmodule AzarApp.Backup do
  @moduledoc false

  alias AzarApp.Repo
  alias AzarApp.Cuentas.{Usuario, Transaccion}
  alias AzarApp.Sorteos.{Sorteo, Ticket}
  import Ecto.Query

  @carpeta "priv/backup"


  @doc """
  Breve: exportar_todo.
  """
  def exportar_todo() do
    File.mkdir_p!(@carpeta)

    exportar_usuarios()
    exportar_sorteos()
    exportar_tickets()
    exportar_transacciones()

    :ok
  end

  @doc """
  Breve: exportar_usuarios.
  """
  def exportar_usuarios() do
    datos = Repo.all(from u in Usuario, order_by: u.id)
    |> Enum.map(&usuario_a_map/1)

    escribir_json("usuarios.json", datos)
  end

  @doc """
  Breve: exportar_sorteos.
  """
  def exportar_sorteos() do
    datos = Repo.all(from s in Sorteo, order_by: s.id)
    |> Enum.map(&sorteo_a_map/1)

    escribir_json("sorteos.json", datos)
  end

  @doc """
  Breve: exportar_tickets.
  """
  def exportar_tickets() do
    datos = Repo.all(from t in Ticket, order_by: t.id)
    |> Enum.map(&ticket_a_map/1)

    escribir_json("tickets.json", datos)
  end

  @doc """
  Breve: exportar_transacciones.
  """
  def exportar_transacciones() do
    datos = Repo.all(from t in Transaccion, order_by: t.id)
    |> Enum.map(&transaccion_a_map/1)

    escribir_json("transacciones.json", datos)
  end


  @doc """
  Breve: leer.
  """
  def leer(archivo) do
    path = Path.join(@carpeta, archivo)
    case File.read(path) do
      {:ok, contenido} ->
        case Jason.decode(contenido) do
          {:ok, data} -> data
          _ -> []
        end
      _ -> []
    end
  end

  @doc """
  Breve: leer_usuarios.
  """
  def leer_usuarios(),       do: leer("usuarios.json")
  @doc """
  Breve: leer_sorteos.
  """
  def leer_sorteos(),        do: leer("sorteos.json")
  @doc """
  Breve: leer_tickets.
  """
  def leer_tickets(),        do: leer("tickets.json")
  @doc """
  Breve: leer_transacciones.
  """
  def leer_transacciones(),  do: leer("transacciones.json")


  @doc """
  Breve: limpiar_todo.
  """
  def limpiar_todo() do
    escribir_json("usuarios.json", [])
    escribir_json("sorteos.json", [])
    escribir_json("tickets.json", [])
    escribir_json("transacciones.json", [])
    :ok
  end


  defp usuario_a_map(u) do
    %{
      id:              u.id,
      email:           u.email,
      nombre:          u.nombre,
      cedula:          u.cedula,
      edad:            u.edad,
      rol:             u.rol,
      activo:          u.activo,
      saldo_virtual:   to_string(u.saldo_virtual),
      total_recargado: to_string(u.total_recargado),
      total_gastado:   to_string(u.total_gastado),
      total_ganado:    to_string(u.total_ganado),
      ultimo_login:    naive_to_str(u.ultimo_login),
      insertado:       to_string(u.inserted_at)
    }
  end

  defp sorteo_a_map(s) do
    %{
      id:               s.id,
      titulo:           s.titulo,
      descripcion:      s.descripcion,
      precio_ticket:    to_string(s.precio_ticket),
      total_tickets:    s.total_tickets,
      cantidad_ganadores: s.cantidad_ganadores,
      tipo_premio:      s.tipo_premio,
      premio_fijo:      to_string(s.premio_fijo),
      porcentaje_casa:  s.porcentaje_casa,
      estado:           s.estado,
      numeros_ganadores: s.numeros_ganadores,
      fecha_ejecucion:  naive_to_str(s.fecha_ejecucion),
      insertado:        to_string(s.inserted_at)
    }
  end

  defp ticket_a_map(t) do
    %{
      id:         t.id,
      numero:     t.numero,
      estado:     t.estado,
      sorteo_id:  t.sorteo_id,
      usuario_id: t.usuario_id,
      insertado:  to_string(t.inserted_at)
    }
  end

  defp transaccion_a_map(t) do
    %{
      id:            t.id,
      tipo:          t.tipo,
      monto:         to_string(t.monto),
      descripcion:   t.descripcion,
      ticket_numero: t.ticket_numero,
      usuario_id:    t.usuario_id,
      sorteo_id:     t.sorteo_id,
      insertado:     to_string(t.inserted_at)
    }
  end

  defp naive_to_str(nil), do: nil
  defp naive_to_str(dt),  do: NaiveDateTime.to_string(dt)


  defp escribir_json(nombre, datos) do
    path = Path.join(@carpeta, nombre)
    File.mkdir_p!(@carpeta)
    File.write!(path, Jason.encode!(datos, pretty: true))
  end
end
