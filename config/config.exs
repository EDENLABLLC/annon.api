use Mix.Config

config :annon_api,
  ecto_repos: [Annon.Configuration.Repo, Annon.Requests.Repo],
  sql_sandbox: {:system, :boolean, "SQL_SANDBOX", false},
  protected_headers: {:system, :list, "PROTECTED_HEADERS", [
    "x-consumer-id", "x-consumer-scope", "x-consumer-token", "x-consumer-token-id", "x-consumer-metadata"
  ]}

config :annon_api, Annon.Configuration.Repo,
  adapter: Ecto.Adapters.Postgres,
  priv: "priv/repos/configuration",
  database: {:system, "DB_NAME", "annon_api_configs"},
  username: {:system, "DB_USER", "postgres"},
  password: {:system, "DB_PASSWORD", "postgres"},
  hostname: {:system, "DB_HOST", "localhost"},
  port: {:system, :integer, "DB_PORT", 5432},
  pool_size: 10,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :annon_api, Annon.Requests.Repo,
  adapter: Ecto.Adapters.Postgres,
  priv: "priv/repos/requests",
  database: {:system, "DB_NAME", "annon_api_logger"},
  username: {:system, "DB_USER", "postgres"},
  password: {:system, "DB_PASSWORD", "postgres"},
  hostname: {:system, "DB_HOST", "localhost"},
  port: {:system, :integer, "DB_PORT", 5432},
  pool_size: 50,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :annon_api, :configuration_cache,
  adapter: {:system, :module, "CONFIGURATION_CACHE_ADAPTER", Annon.Configuration.CacheAdapters.ETS},
  cache_space: :configuration

config :annon_api, :plugin_pipeline,
  default_features: []

# Configures Elixir's Logger
config :logger, :console,
  format: "$message\n",
  handle_otp_reports: true,
  level: :info

import_config "clustering.exs"
import_config "monitoring.exs"
import_config "plugins.exs"
import_config "http.exs"

if Mix.env == :test do
  import_config "test.exs"
end
