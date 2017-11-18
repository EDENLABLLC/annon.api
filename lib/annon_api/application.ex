defmodule Annon do
  @moduledoc """
  This is an entry point of Annon application.
  """
  use Application
  alias Confex.Resolver

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Annon.Configuration.Repo, []),
      supervisor(Annon.Requests.Repo, []),
      worker(DogStat, [metrics_collector_opts()]),
      worker(Annon.Requests.LogWriter, []),
      worker(Annon.Configuration.Matcher, [matcher_opts()]),
      worker(Annon.AutoClustering, []),
      management_endpoint_spec(),
      supervisor(Annon.PublicAPI.ServerSupervisor, []),
    ]

    opts = [strategy: :one_for_one, name: Annon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def management_endpoint_spec do
    config = Confex.get_env(:annon_api, :management_http)
    Plug.Adapters.Cowboy.child_spec(:http, Annon.ManagementAPI.Router, [], config)
  end

  defp matcher_opts do
    Application.get_env(:annon_api, :configuration_cache)
  end

  defp metrics_collector_opts do
    Confex.get_env(:annon_api, :metrics_collector)
  end

  # Loads configuration in `:init` callbacks and replaces `{:system, ..}` tuples via Confex
  @doc false
  def init(_key, config) do
    Resolver.resolve(config)
  end
end
