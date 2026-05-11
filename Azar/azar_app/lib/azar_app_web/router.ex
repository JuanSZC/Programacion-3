defmodule AzarAppWeb.Router do
  use AzarAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AzarAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AzarAppWeb.Plugs.CargarUsuario
  end

  pipeline :require_auth do
    plug AzarAppWeb.Plugs.RequireAuth
  end

  pipeline :require_admin do
    plug AzarAppWeb.Plugs.RequireAdmin
  end

  scope "/", AzarAppWeb do
    pipe_through :browser

    live "/", AzarLive, :home
    live "/login", AuthLive.LoginLive, :login
    live "/registro", AuthLive.RegistroLive, :registros
    live "/admin/login", AuthLive.AdminLoginLive, :admin_login

    # RUTAS DE SESIÓN (Limpiadas y sin duplicados)
    post "/sesion", SesionController, :crear
    get "/sesion/validar", SesionController, :crear
    post "/sesion/validar", SesionController, :crear
    delete "/sesion", SesionController, :borrar
  end

  # PANEL DE ADMINISTRACIÓN
  scope "/admin", AzarAppWeb do
    pipe_through [:browser, :require_admin]

    live "/sorteos", Admin.SorteoLive.Index, :index
    live "/sorteos/new", Admin.SorteoLive.Index, :new
    live "/sorteos/:id/edit", Admin.SorteoLive.Index, :edit

    # Si te sigue dando error de "module Show is undefined",
    # comenta la siguiente línea con un # hasta que crees ese archivo.
    live "/sorteos/:id", Admin.SorteoLive.Show, :show
  end

# PANEL DE CLIENTE
  scope "/cliente", AzarAppWeb.Cliente do # <-- Agregamos .Cliente aquí
    pipe_through [:browser, :require_auth]

    live "/perfil", PerfilLive, :index
    live "/sorteos", SorteosLive, :index
    live "/sorteos/:id", SorteoDetalleLive, :show # Cambié el nombre para evitar conflictos
    delete "/sesion", SesionController, :borrar
  end
end
