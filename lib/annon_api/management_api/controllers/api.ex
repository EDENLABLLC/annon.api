defmodule Annon.ManagementAPI.Controllers.API do
  @moduledoc """
  REST interface that allows to manage API's and their settings.

  API is a core entity that tells what host, port, path Annon should listen.
  After creating API you can assign plugins to it.

  You can find full description in [REST API documentation](http://docs.annon.apiary.io/#reference/apis).
  """
  use Annon.ManagementAPI.ControllersRouter
  alias Annon.Configuration.API, as: ConfigurationAPI
  alias Annon.Configuration.Schemas.API, as: APISchema

  get "/" do
    conn
    |> Map.fetch!(:query_params)
    |> Map.take(~w(name page_size page))
    |> ConfigurationAPI.list_apis()
    |> render_collection_with_pagination(conn)
  end

  get "/:api_id" do
    api_id
    |> ConfigurationAPI.get_api()
    |> render_one(conn)
  end

  put "/:api_id" do
    with {:ok, api_params} <- Map.fetch(conn.body_params, "api") do
      case ConfigurationAPI.get_api(api_id) do
        {:ok, %APISchema{} = api} ->
          api
          |> ConfigurationAPI.update_api(api_params)
          |> render_one(conn, 200)

        {:error, :not_found} ->
          api_id
          |> ConfigurationAPI.create_api(api_params)
          |> render_one(conn, 201)
      end
    else
      :error -> send_error(conn, :no_root_object, "api")
    end
  end

  delete "/:api_id" do
    case ConfigurationAPI.get_api(api_id) do
      {:ok, api} ->
        ConfigurationAPI.delete_api(api)
        render_delete(conn)
      {:error, :not_found} ->
        render_delete(conn)
    end
  end

  forward "/", to: Annon.ManagementAPI.Controllers.APIPlugin
end
