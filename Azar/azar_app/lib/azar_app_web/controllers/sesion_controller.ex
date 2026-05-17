defmodule AzarAppWeb.SesionController do
  @moduledoc """
  Módulo AzarAppWeb.SesionController: lógica relacionada con sesioncontroller.
  """

  use AzarAppWeb, :controller

  alias AzarApp.Cuentas

  @doc """
  Breve: crear.
  """
  def crear(conn, %{"email" => email, "password" => password, "tipo" => tipo}) do
    case Cuentas.autenticar_usuario(email, password) do
      {:ok, usuario} ->

        AzarApp.Auditoria.log(:sesion_iniciada, %{
          usuario_id: usuario.id,
          email: usuario.email,
          rol: usuario.rol
        })

        intentando_admin = tipo == "admin"
        es_admin = usuario.rol == "admin"

        cond do
          intentando_admin and not es_admin ->
            conn
            |> put_flash(:error, "Acceso denegado. Se requieren permisos de administrador.")
            |> redirect(to: ~p"/admin/login")
            |> halt()

          true ->
            ruta =
              if es_admin,
                do: ~p"/admin/sorteos",
                else: ~p"/cliente/sorteos"

            iniciar_sesion(conn, usuario, ruta)
        end

      {:error, _razon} ->
        ruta_origen =
          if tipo == "admin",
            do: ~p"/admin/login",
            else: ~p"/login"

        conn
        |> put_flash(:error, "Correo o contraseña incorrectos.")
        |> redirect(to: ruta_origen)
        |> halt()
    end
  end

  defp iniciar_sesion(conn, usuario, ruta_destino) do
    conn
    |> put_session(:usuario_id, usuario.id)
    |> configure_session(renew: true)
    |> put_flash(:info, "¡Bienvenido, #{usuario.nombre}!")
    |> redirect(to: ruta_destino)
  end

  @doc """
  Breve: borrar.
  """
  def borrar(conn, _params) do
    usuario_id = get_session(conn, :usuario_id)

    if usuario_id do
      usuario = AzarApp.Cuentas.obtener_usuario!(usuario_id)

      AzarApp.Auditoria.log(:sesion_cerrada, %{
        usuario_id: usuario.id,
        email: usuario.email
      })
    end

    conn
    |> clear_session()
    |> put_flash(:info, "Sesión cerrada correctamente.")
    |> redirect(to: ~p"/")
  end
end
