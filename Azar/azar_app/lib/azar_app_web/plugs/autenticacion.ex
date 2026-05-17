defmodule AzarAppWeb.Plugs.Autenticacion do
  @moduledoc false
end

defmodule AzarAppWeb.Plugs.CargarUsuario do
  import Plug.Conn
  alias AzarApp.Cuentas

  @doc """
  Breve: init.
  """
  def init(opts), do: opts

  @doc """
  Breve: call.
  """
  def call(conn, _opts) do
    usuario_id = get_session(conn, :usuario_id)

    usuario =
      if usuario_id do
        case Cuentas.obtener_usuario(usuario_id) do
          {:ok, usuario} -> usuario
          _ -> nil
        end
      else
        nil
      end

    assign(conn, :usuario_actual, usuario)
  end
end

defmodule AzarAppWeb.Plugs.RequireAuth do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]
  alias AzarApp.Cuentas

  @doc """
  Breve: init.
  """
  def init(opts), do: opts

  @doc """
  Breve: call.
  """
  def call(conn, _opts) do
    usuario_id = get_session(conn, :usuario_id)

    usuario =
      if usuario_id do
        case Cuentas.obtener_usuario(usuario_id) do
          {:ok, usuario} -> usuario
          _ -> nil
        end
      else
        nil
      end

    if usuario && usuario.activo do
      assign(conn, :usuario_actual, usuario)
    else
      conn
      |> put_flash(:error, "Debes iniciar sesión para continuar.")
      |> redirect(to: "/login")
      |> halt()
    end
  end
end

defmodule AzarAppWeb.Plugs.RequireAdmin do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]
  alias AzarApp.Cuentas

  @doc """
  Breve: init.
  """
  def init(opts), do: opts

  @doc """
  Breve: call.
  """
  def call(conn, _opts) do
    usuario_id = get_session(conn, :usuario_id)

    usuario =
      if usuario_id do
        case Cuentas.obtener_usuario(usuario_id) do
          {:ok, usuario} -> usuario
          _ -> nil
        end
      else
        nil
      end

    if usuario && usuario.activo && usuario.rol == "admin" do
      assign(conn, :usuario_actual, usuario)
    else
      conn
      |> put_flash(:error, "Acceso restringido a administradores.")
      |> redirect(to: "/admin/login")
      |> halt()
    end
  end
end
