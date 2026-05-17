defmodule AzarApp.Admin do
  @moduledoc """
  Módulo AzarApp.Admin: lógica relacionada con admin.
  """

  defstruct [
    nombre_app: "Azar UQ Pro",
    total_recaudado: 0,
    ventas_realizadas: 0,
    limite_apuestas_por_persona: 5,
    estado_plataforma: :operativa # :operativa, :mantenimiento
  ]


  @doc """
  Breve: registrar_venta_global.
  """
  def registrar_venta_global(%__MODULE__{} = admin, monto) do
    %{admin |
      total_recaudado: admin.total_recaudado + monto,
      ventas_realizadas: admin.ventas_realizadas + 1
    }
  end


  @doc """
  Breve: reporte_estado.
  """
  def reporte_estado(%__MODULE__{total_recaudado: total, ventas_realizadas: ventas}) do
    """
    --- REPORTE DE ADMIN ---
    Ventas totales: #{ventas}
    Dinero en caja: $#{total}
    Promedio por venta: #{if ventas > 0, do: total / ventas, else: 0}
    ------------------------
    """
  end


  @doc """
  Breve: cambiar_estado.
  """
  def cambiar_estado(%__MODULE__{} = admin, nuevo_estado) do
    %{admin | estado_plataforma: nuevo_estado}
  end
end
