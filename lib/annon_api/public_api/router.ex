defmodule Annon.PublicAPI.Router do
  @moduledoc """
  Router for a Annons public API.

  It has all available plugins assigned (in a specific order),
  but witch of them should process request will be resolved in run-time.
  """
  use Plug.Router

  if Confex.get_env(:annon_api, :sql_sandbox) do
    plug Annon.Requests.Sandbox
    plug Phoenix.Ecto.SQL.Sandbox
  end

  require Logger

  use Plug.ErrorHandler

  alias Plug.LoggerJSON

  plug :match

  plug Plug.Head
  plug Plug.RequestId
  plug EView.Plugs.Idempotency
  plug Plug.LoggerJSON, level: Logger.level

  plug Plug.Parsers, parsers: [:json],
                     pass: ["*/*"],
                     json_decoder: Poison,
                     length: 8_388_608,       # Read maximum of 8 MB of JSON data
                     read_length: 1_048_576,  # in 1 Mb chinks
                     read_timeout: 15_000     # 15 seconds with timeout between chunks

  plug Annon.Plugin.PipelinePlug

  plug :dispatch

  match _ do
    Annon.Helpers.Response.send_error(conn, :not_found)
  end

  defp handle_errors(%Plug.Conn{status: 500} = conn, %{kind: kind, reason: reason, stack: stacktrace} = error) do
    LoggerJSON.log_error(kind, reason, stacktrace)
    Annon.Helpers.Response.send_error(conn, error)
  end

  defp handle_errors(_, _), do: nil
end
