defmodule Annon.Configuration.CacheAdapters.ETS do
  @moduledoc """
  Adapter to access cache using ETS.
  """
  @behaviour Annon.Configuration.CacheAdapter
  alias Annon.Configuration.API

  def init(opts) do
    table_name = Keyword.fetch!(opts, :cache_space)
    :ets.new(table_name, [:ordered_set, :public, :named_table, read_concurrency: true])
    config_change(opts)
    :ok
  end

  def match_request(scheme, method, host, port, path, opts) do
    table_name = Keyword.fetch!(opts, :cache_space)

    match_spec = %{
      request: %{
        scheme: scheme,
        port: port
      }
    }

    apis =
      table_name
      # TODO: Try QLC to filter by methods
      |> :ets.match_object({:_, match_spec, :_, :_})
      |> filter_by_method(method)
      |> filter_by_host(host)
      |> filter_by_path(path)

    case apis do
      [] ->
        {:error, :not_found}
      [{_, api, _, _}|_] ->
        {:ok, api}
    end
  end

  def config_change(opts) do
    table_name = Keyword.fetch!(opts, :cache_space)

    apis = API.dump_apis()
    objects = Enum.map(apis, fn api ->
      priority = -api.matching_priority
      {{priority, api.id}, api, compile_host_regex(api.request.host), compile_path_regex(api.request.path)}
    end)

    apis
    |> Enum.reduce([], fn api, acc ->
      api.plugins
      |> Enum.filter(&(Map.get(&1, :name) == "proxy"))
      |> Enum.reduce(acc, &get_pools/2)
    end)
    |> Enum.each(fn domain ->
      :ok = :hackney_pool.start_pool(domain, [timeout: 15_000, max_connections: 100])
    end)

    case objects do
      [] ->
        :ok
      objects when is_list(objects) ->
        true = :ets.delete_all_objects(table_name)
        true = :ets.insert(table_name, objects)
        :ok
    end
  end

  defp get_pools(plugin, pools) do
    host = plugin.settings["host"]
    if host in pools do
      pools
    else
      [host | pools]
    end
  end

  defp filter_by_method(apis, method) do
    Enum.filter(apis, fn({_, api, _, _}) ->
      method in api.request.methods
    end)
  end

  defp compile_host_regex(host) do
    host_pattern = prepare_regex(host)
    Regex.compile!("^#{host_pattern}$")
  end

  defp filter_by_host(apis, host) do
    Enum.filter(apis, fn({_, _, host_regex, _}) ->
      Regex.match?(host_regex, host)
    end)
  end

  defp compile_path_regex(path) do
    path_pattern = prepare_regex(path)
    Regex.compile!("^#{path_pattern}")
  end

  defp filter_by_path(apis, path) do
    Enum.filter(apis, fn({_, _, _, path_regex}) ->
      Regex.match?(path_regex, path)
    end)
  end

  defp prepare_regex(string) do
    string
    |> Regex.escape()
    |> String.replace("%", ".*")
    |> String.replace("_", ".{1}") # TODO: Paths like /my_path/ will match /myXpath/ which is BAD
  end
end
