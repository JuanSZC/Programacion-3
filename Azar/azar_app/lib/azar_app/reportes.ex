defmodule AzarApp.Reportes do
  @moduledoc false

  import Ecto.Query, warn: false

  alias AzarApp.Repo
  alias AzarApp.Cuentas.Usuario
  alias AzarApp.Sorteos.{Sorteo, Ticket}


  @doc """
  Breve: stats_usuarios.
  """
  def stats_usuarios do
    total = Repo.aggregate(Usuario, :count, :id) || 0

    activos =
      Repo.aggregate(
        from(u in Usuario, where: u.activo == true),
        :count,
        :id
      ) || 0

    inactivos = total - activos

    con_compras =
      Repo.aggregate(
        from(u in Usuario,
          join: t in Ticket,
          on: t.usuario_id == u.id,
          where: t.estado == "vendido",
          distinct: u.id
        ),
        :count,
        :id
      ) || 0

    sin_compras = total - con_compras

    inicio_mes =
      Date.beginning_of_month(Date.utc_today())
      |> NaiveDateTime.new!(~T[00:00:00])

    nuevos_mes =
      Repo.aggregate(
        from(u in Usuario, where: u.inserted_at >= ^inicio_mes),
        :count,
        :id
      ) || 0

    inicio_anio =
      Date.new!(Date.utc_today().year, 1, 1)
      |> NaiveDateTime.new!(~T[00:00:00])

    nuevos_por_mes =
      Repo.all(
        from u in Usuario,
          where: u.inserted_at >= ^inicio_anio,
          group_by: fragment("EXTRACT(MONTH FROM ?)", u.inserted_at),
          select: {
            fragment("EXTRACT(MONTH FROM ?)", u.inserted_at),
            count(u.id)
          },
          order_by: fragment("EXTRACT(MONTH FROM ?)", u.inserted_at)
      )
      |> Enum.map(fn {mes, cnt} ->
        {mes |> Decimal.new() |> Decimal.to_integer(), cnt}
      end)

    %{
      total: total,
      activos: activos,
      inactivos: inactivos,
      con_compras: con_compras,
      sin_compras: sin_compras,
      nuevos_mes: nuevos_mes,
      nuevos_por_mes: nuevos_por_mes
    }
  end


  @doc """
  Breve: top_compradores.
  """
  def top_compradores(limit \\ 5) do
    Repo.all(
      from u in Usuario,
        where: not is_nil(u.total_gastado) and u.total_gastado > 0,
        order_by: [desc: u.total_gastado],
        limit: ^limit,
        select: %{
          id: u.id,
          nombre: u.nombre,
          email: u.email,
          total_gastado: u.total_gastado,
          saldo_virtual: u.saldo_virtual,
          total_ganado: u.total_ganado
        }
    )
  end

  @doc """
  Breve: top_ganadores.
  """
  def top_ganadores(limit \\ 5) do
    Repo.all(
      from u in Usuario,
        where: not is_nil(u.total_ganado) and u.total_ganado > 0,
        order_by: [desc: u.total_ganado],
        limit: ^limit,
        select: %{
          id: u.id,
          nombre: u.nombre,
          email: u.email,
          total_ganado: u.total_ganado,
          total_gastado: u.total_gastado,
          saldo_virtual: u.saldo_virtual
        }
    )
  end


  @doc """
  Breve: stats_financieras.
  """
  def stats_financieras do
    total_gastado_usuarios =
      Repo.one(
        from u in Usuario,
          select: coalesce(sum(u.total_gastado), 0)
      ) || Decimal.new(0)

    total_ganado_usuarios =
      Repo.one(
        from u in Usuario,
          select: coalesce(sum(u.total_ganado), 0)
      ) || Decimal.new(0)

    saldo_en_circulacion =
      Repo.one(
        from u in Usuario,
          select: coalesce(sum(u.saldo_virtual), 0)
      ) || Decimal.new(0)

    ganancia_casa =
      Decimal.sub(total_gastado_usuarios, total_ganado_usuarios)

    recaudo_sorteos =
      Repo.all(
        from s in Sorteo,
          join: t in Ticket,
          on: t.sorteo_id == s.id and t.estado == "vendido",
          group_by: [s.id, s.precio_ticket],
          select: {count(t.id), s.precio_ticket}
      )
      |> Enum.reduce(Decimal.new(0), fn {cnt, precio}, acc ->
        subtotal =
          Decimal.mult(
            Decimal.new(cnt),
            decimal_seguro(precio)
          )

        Decimal.add(acc, subtotal)
      end)

    %{
      total_gastado_usuarios: total_gastado_usuarios,
      total_ganado_usuarios: total_ganado_usuarios,
      saldo_en_circulacion: saldo_en_circulacion,
      ganancia_casa: ganancia_casa,
      recaudo_sorteos: recaudo_sorteos
    }
  end


  @doc """
  Breve: stats_sorteos.
  """
  def stats_sorteos do
    total = Repo.aggregate(Sorteo, :count, :id) || 0

    activos =
      Repo.aggregate(
        from(s in Sorteo, where: s.estado == "activo"),
        :count,
        :id
      ) || 0

    finalizados =
      Repo.aggregate(
        from(s in Sorteo, where: s.estado == "finalizado"),
        :count,
        :id
      ) || 0

    cancelados =
      Repo.aggregate(
        from(s in Sorteo, where: s.estado == "cancelado"),
        :count,
        :id
      ) || 0

    fijos =
      Repo.aggregate(
        from(s in Sorteo, where: s.tipo_premio == "fijo"),
        :count,
        :id
      ) || 0

    acumulados =
      Repo.aggregate(
        from(s in Sorteo, where: s.tipo_premio == "acumulado"),
        :count,
        :id
      ) || 0

    tasa_exito =
      if finalizados + cancelados > 0 do
        Float.round(finalizados / (finalizados + cancelados) * 100, 1)
      else
        0.0
      end

    %{
      total: total,
      activos: activos,
      finalizados: finalizados,
      cancelados: cancelados,
      fijos: fijos,
      acumulados: acumulados,
      tasa_exito: tasa_exito
    }
  end


  @doc """
  Breve: proximos_sorteos.
  """
  def proximos_sorteos(limit \\ 10) do
    ahora = NaiveDateTime.utc_now()

    Repo.all(
      from s in Sorteo,
        where:
          s.estado == "activo" and
            not is_nil(s.fecha_ejecucion) and
            s.fecha_ejecucion > ^ahora,
        order_by: [asc: s.fecha_ejecucion],
        limit: ^limit,
        select: %{
          id: s.id,
          titulo: s.titulo,
          fecha_ejecucion: s.fecha_ejecucion,
          tipo_premio: s.tipo_premio,
          precio_ticket: s.precio_ticket,
          total_tickets: s.total_tickets
        }
    )
  end


  @doc """
  Breve: stats_tickets.
  """
  def stats_tickets do
    total = Repo.aggregate(Ticket, :count, :id) || 0

    vendidos =
      Repo.aggregate(
        from(t in Ticket, where: t.estado == "vendido"),
        :count,
        :id
      ) || 0

    disponibles = total - vendidos

    tasa_venta =
      if total > 0 do
        Float.round(vendidos / total * 100, 1)
      else
        0.0
      end

    top_sorteos_tickets =
      Repo.all(
        from t in Ticket,
          join: s in Sorteo,
          on: t.sorteo_id == s.id,
          where: t.estado == "vendido",
          group_by: [s.id, s.titulo],
          select: %{
            sorteo_id: s.id,
            titulo: s.titulo,
            vendidos: count(t.id)
          },
          order_by: [desc: count(t.id)],
          limit: 5
      )

    %{
      total: total,
      vendidos: vendidos,
      disponibles: disponibles,
      tasa_venta: tasa_venta,
      top_sorteos_tickets: top_sorteos_tickets
    }
  end


  @doc """
  Breve: actividad_reciente.
  """
  def actividad_reciente(limit \\ 10) do
    Repo.all(
      from t in Ticket,
        join: u in Usuario,
        on: t.usuario_id == u.id,
        join: s in Sorteo,
        on: t.sorteo_id == s.id,
        where: t.estado == "vendido",
        order_by: [desc: t.updated_at],
        limit: ^limit,
        select: %{
          usuario_nombre: u.nombre,
          sorteo_titulo: s.titulo,
          numero_ticket: t.numero,
          precio: s.precio_ticket,
          fecha: t.updated_at
        }
    )
  end


  @doc """
  Breve: recaudo_por_mes.
  """
  def recaudo_por_mes do
    inicio_anio =
      Date.new!(Date.utc_today().year, 1, 1)
      |> NaiveDateTime.new!(~T[00:00:00])

    Repo.all(
      from t in Ticket,
        join: s in Sorteo,
        on: t.sorteo_id == s.id,
        where:
          t.estado == "vendido" and
            t.updated_at >= ^inicio_anio,
        group_by: fragment("EXTRACT(MONTH FROM ?)", t.updated_at),
        order_by: fragment("EXTRACT(MONTH FROM ?)", t.updated_at),
        select: %{
          mes:
            fragment(
              "EXTRACT(MONTH FROM ?)",
              t.updated_at
            ),
          recaudo:
            sum(s.precio_ticket)
        }
    )
    |> Enum.map(fn %{mes: mes, recaudo: recaudo} ->
      %{
        mes: Decimal.to_integer(mes),
        recaudo: decimal_seguro(recaudo)
      }
    end)
  end


  @doc """
  Breve: resumen_completo.
  """
  def resumen_completo do
    %{
      usuarios: stats_usuarios(),
      financiero: stats_financieras(),
      sorteos: stats_sorteos(),
      tickets: stats_tickets(),
      top_compradores: top_compradores(),
      top_ganadores: top_ganadores(),
      proximos_sorteos: proximos_sorteos(),
      actividad_reciente: actividad_reciente(),
      recaudo_por_mes: recaudo_por_mes(),
      sorteos_sin_fecha: []
    }
  end


  defp decimal_seguro(nil), do: Decimal.new(0)
  defp decimal_seguro(%Decimal{} = v), do: v
  defp decimal_seguro(v), do: Decimal.new(to_string(v))
end
