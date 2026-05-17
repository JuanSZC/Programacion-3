defmodule AzarApp.Application do
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
      AzarApp.Core.SorteoSupervisor,
      AzarApp.Sorteos.Scheduler,
      Supervisor.child_spec({Task, fn -> AzarApp.Core.SorteoSupervisor.restaurar_sorteos() end}, restart: :temporary)

    ]

    opts = [strategy: :one_for_one, name: AzarApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    AzarAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
