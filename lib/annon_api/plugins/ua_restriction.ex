defmodule Annon.Plugins.UARestriction do
  @moduledoc """
  It allows to white/black-list consumers by user agent.

  TODO: refactor validation from this file and pre-compile patterns for reuse
  """
  use Annon.Plugin, plugin_name: :ua_restriction
  alias EView.Views.Error, as: ErrorView
  alias Annon.Helpers.Response
  require Logger

  defdelegate validate_settings(changeset), to: Annon.Plugins.UARestriction.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.UARestriction.SettingsValidator

  def execute(%Conn{} = conn, _request, settings) do
    with true <- check_headers(settings, conn.headers) do
      conn
    else
      :error ->
        Logger.warn("Request does not contain User-Agent header, User Agent restrictions won't be applied")
        conn
      false ->
        render_forbidden(conn)
    end
  end

  defp check_headers(settings, headers) do
    blacklisted = blacklisted?(settings, headers)
    whitelisted = whitelisted?(settings, headers)
    whitelisted || (whitelisted === nil && !blacklisted)
  end

  defp whitelisted?(%{"whitelist" => list}, headers),
    do: Enum.all?(header_matches?(list, headers), &(&1 == true))
  defp whitelisted?(_plugin, _user_agent),
    do: nil

  defp blacklisted?(%{"blacklist" => list}, headers),
    do: Enum.all?(header_matches?(list, headers), &(&1 == true))
  defp blacklisted?(_plugin, _user_agent),
    do: nil

  defp header_matches?(listed_headers, headers) do
    for %{"name" => listed_name, "values" => listed_values} <- listed_headers,
        {name, values} <- headers,
        name == listed_name
    do
      Enum.any? listed_values, fn regex ->
        Enum.any? values, fn value ->
          regex
          |> Regex.compile!()
          |> Regex.match?(value)
        end
      end
    end
  end

  def render_forbidden(conn) do
    "403.json"
    |> ErrorView.render(%{message: "You has been blocked from accessing this resource"})
    |> Response.send(conn, 403)
    |> Response.halt()
  end
end
