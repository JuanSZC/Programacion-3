defmodule AzarApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
children = [
      AzarAppWeb.Telemetry,
      AzarApp.Repo,
      {DNSCluster, query: Application.get_env(:azar_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AzarApp.PubSub},
      AzarAppWeb.Endpoint,
      AzarApp.BackupSync,
      # Tus módulos core aquí abajo:
      AzarApp.Core.SorteoSupervisor,
      # Tarea que arranca los sorteos guardados una vez el supervisor ya está listo
      AzarApp.Sorteos.Scheduler,
      Supervisor.child_spec({Task, fn -> AzarApp.Core.SorteoSupervisor.restaurar_sorteos() end}, restart: :temporary)

    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AzarApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AzarAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
