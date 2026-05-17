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

    post "/sesion", SesionController, :crear
    delete "/sesion", SesionController, :borrar

    get "/forzar_logout", SesionForzadaController, :cerrar
  end

  # PANEL DE ADMINISTRACIÓN
  scope "/admin", AzarAppWeb do
    pipe_through [:browser, :require_admin]

    live "/sorteos", Admin.SorteoLive.Index, :index
    live "/sorteos/new", Admin.SorteoLive.Index, :new
    live "/sorteos/:id/edit", Admin.SorteoLive.Index, :edit
    live "/sorteos/:id", Admin.SorteoLive.Show, :show
    live "/usuarios", Admin.UsuarioLive.Index, :index
    live "/usuarios/:id", Admin.UsuarioLive.Show, :show
    live "/dashboard", Admin.DashboardLive, :index
    live "/perfil", Admin.PerfilLive, :index
  end

  # PANEL DE CLIENTE
  scope "/cliente", AzarAppWeb.Cliente do
    pipe_through [:browser, :require_auth]

    live_session :cliente,
      on_mount: [AzarAppWeb.Cliente.NotificacionHook],
      layout: {AzarAppWeb.Layouts, :cliente} do

      live "/perfil", PerfilLive, :index
      live "/sorteos", SorteosLive, :index
      live "/sorteos/:id", SorteoDetalleLive, :show
    end
  end

end
