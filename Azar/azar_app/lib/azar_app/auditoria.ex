defmodule AzarApp.Auditoria do
  @moduledoc false

  @log_path "log/auditoria.log"





  def log(:sesion_iniciada, %{usuario_id: id, email: email, rol: rol}) do
    escribir("SESION_INICIADA", "usuario_id=#{id} email=#{email} rol=#{rol}")
  end




  def log(:sesion_cerrada, %{usuario_id: id, email: email}) do
    escribir("SESION_CERRADA", "usuario_id=#{id} email=#{email}")
  end




  def log(:usuario_creado, %{usuario_id: id, email: email, rol: rol}) do
    escribir("USUARIO_CREADO", "usuario_id=#{id} email=#{email} rol=#{rol}")
  end




  def log(:usuario_eliminado, %{usuario_id: id, email: email}) do
    escribir("USUARIO_ELIMINADO", "usuario_id=#{id} email=#{email}")
  end




  def log(:usuario_activado, %{usuario_id: id}) do
    escribir("USUARIO_ACTIVADO", "usuario_id=#{id}")
  end




  def log(:usuario_desactivado, %{usuario_id: id}) do
    escribir("USUARIO_DESACTIVADO", "usuario_id=#{id}")
  end




  def log(:recarga_saldo, %{usuario_id: id, monto: monto, metodo: metodo}) do
    escribir("RECARGA_SALDO", "usuario_id=#{id} monto=#{monto} metodo=#{metodo}")
  end




  def log(:saldo_ajustado_admin, %{usuario_id: id, monto: monto, operacion: op, admin_id: admin_id}) do
    escribir("SALDO_AJUSTADO_ADMIN", "admin_id=#{admin_id} usuario_id=#{id} operacion=#{op} monto=#{monto}")
  end




  def log(:cuenta_vaciada_admin, %{usuario_id: id, admin_id: admin_id}) do
    escribir("CUENTA_VACIADA_ADMIN", "admin_id=#{admin_id} usuario_id=#{id}")
  end




  def log(:ticket_comprado, %{usuario_id: id, sorteo_id: sid, numero: num, monto: monto}) do
    escribir("TICKET_COMPRADO", "usuario_id=#{id} sorteo_id=#{sid} ticket=##{num} monto=#{monto}")
  end




  def log(:ticket_devuelto, %{usuario_id: id, sorteo_id: sid, numero: num, monto: monto}) do
    escribir("TICKET_DEVUELTO", "usuario_id=#{id} sorteo_id=#{sid} ticket=##{num} monto_reembolsado=#{monto}")
  end




  def log(:sorteo_creado, %{sorteo_id: id, titulo: titulo, tipo: tipo}) do
    escribir("SORTEO_CREADO", "sorteo_id=#{id} titulo=\"#{titulo}\" tipo=#{tipo}")
  end




  def log(:sorteo_ejecutado, %{sorteo_id: id, titulo: titulo, ganadores: ganadores, premio: premio}) do
    escribir("SORTEO_EJECUTADO", "sorteo_id=#{id} titulo=\"#{titulo}\" ganadores=#{inspect(ganadores)} premio=#{premio}")
  end




  def log(:sorteo_cancelado, %{sorteo_id: id, titulo: titulo, motivo: motivo}) do
    escribir("SORTEO_CANCELADO", "sorteo_id=#{id} titulo=\"#{titulo}\" motivo=\"#{motivo}\"")
  end




  def log(:sorteo_eliminado, %{sorteo_id: id, titulo: titulo}) do
    escribir("SORTEO_ELIMINADO", "sorteo_id=#{id} titulo=\"#{titulo}\"")
  end




  def log(:premio_pagado, %{usuario_id: id, sorteo_id: sid, monto: monto}) do
    escribir("PREMIO_PAGADO", "usuario_id=#{id} sorteo_id=#{sid} monto=#{monto}")
  end




  def log(:devolucion_cancelacion, %{usuario_id: id, sorteo_id: sid, monto: monto}) do
    escribir("DEVOLUCION_CANCELACION", "usuario_id=#{id} sorteo_id=#{sid} monto_reembolsado=#{monto}")

  end



  def log(:sistema_limpiado, %{tickets: t, sorteos: s, usuarios: u}) do
  escribir("SISTEMA_LIMPIADO", "tickets_eliminados=#{t} sorteos_eliminados=#{s} usuarios_eliminados=#{u}")
end


  defp escribir(tipo, detalle) do
    timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_string()
    linea = "[#{timestamp}] [#{tipo}] #{detalle}\n"

    File.mkdir_p!(Path.dirname(@log_path))
    File.write!(@log_path, linea, [:append])

    require Logger
    Logger.info("[AUDITORIA] #{tipo} | #{detalle}")

    :ok
  end

end
