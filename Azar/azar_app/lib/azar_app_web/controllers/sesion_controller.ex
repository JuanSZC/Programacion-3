defmodule AzarAppWeb.SesionController do
  use AzarAppWeb, :controller
  alias AzarApp.Cuentas

  # Procesa el inicio de sesión para Clientes y Admins
  def crear(conn, %{"email" => email, "password" => password, "tipo" => tipo}) do
    case Cuentas.autenticar_usuario(email, password) do
      {:ok, usuario} ->
        intentando_admin = (tipo == "admin")
        es_admin = (usuario.rol == "admin")

        cond do
          # SEGURIDAD: Si intenta entrar por /admin/login pero es un cliente
          intentando_admin and not es_admin ->
            conn
            |> put_flash(:error, "Acceso denegado. Se requieren permisos de administrador.")
            |> redirect(to: ~p"/admin/login")
            |> halt()

          # ÉXITO: Redirige según el rol real del usuario
          true ->
            ruta = if es_admin, do: ~p"/admin/sorteos", else: ~p"/cliente/sorteos"
            iniciar_sesion(conn, usuario, ruta)
        end

      {:error, _razon} ->
        # MANEJO DE EXCEPCIÓN: Si fallan las credenciales, vuelve al login correspondiente
        ruta_origen = if tipo == "admin", do: ~p"/admin/login", else: ~p"/login"
        conn
        |> put_flash(:error, "Correo o contraseña incorrectos.")
        |> redirect(to: ruta_origen)
        |> halt()
    end
  end

  # Función privada para gestionar la cookie de sesión de forma segura
  defp iniciar_sesion(conn, usuario, ruta_destino) do
    conn
    |> put_session(:usuario_id, usuario.id)
    |> configure_session(renew: true) # Regenera el ID de sesión para evitar Session Fixation
    |> put_flash(:info, "¡Bienvenido, #{usuario.nombre}!")
    |> redirect(to: ruta_destino)
  end

  # Cierre de sesión (Logout)
  def borrar(conn, _params) do
    conn
    |> clear_session() # Limpia todos los datos de la cookie
    |> put_flash(:info, "Sesión cerrada correctamente.")
    |> redirect(to: ~p"/")
  end
end
