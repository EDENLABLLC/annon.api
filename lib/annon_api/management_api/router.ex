defmodule Annon.ManagementAPI.Router do
  @moduledoc """
  Router for a [Annons Management API](http://docs.annon.apiary.io/#reference/apis).
  """
  use Plug.Router
  use Plug.ErrorHandler
  alias Annon.Helpers.Response
  alias Annon.ManagementAPI.Controllers

  if Confex.get_env(:annon_api, :sql_sandbox) do
    plug Annon.Requests.Sandbox
    plug Phoenix.Ecto.SQL.Sandbox
  end

  plug :match

  plug Plug.RequestId
  plug Plug.Parsers, parsers: [:json],
                     pass: ["application/json"],
                     json_decoder: Poison

  plug :dispatch

  plug Annon.ManagementAPI.ConfigReloaderPlug,
    subscriber: &Annon.AutoClustering.reload_config/0

  forward "/apis", to: Controllers.API
  forward "/requests", to: Controllers.Request
  forward "/dictionaries", to: Controllers.Dictionaries

  get "/apis_status", do: Controllers.Monitoring.list_apis_status(conn)
  get "/cluster_status", do: Controllers.Monitoring.list_cluster_status(conn)
  get "/requests_metrics", do: Controllers.Monitoring.get_requests_metrics(conn)

  match _ do
    Response.send_error(conn, :not_found)
  end

  def handle_errors(conn, error) do
    Response.send_error(conn, error)
  end
end
