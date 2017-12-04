defmodule Annon.Plugins.Auth.ThirdPartyResolverTest do
  @moduledoc false
  use Annon.ConnCase, async: true
  alias Annon.PublicAPI.Consumer
  alias Annon.Plugins.Auth.ThirdPartyResolver

  setup do
    mock_conf = Confex.get_env(:annon_api, :acceptance)[:mock]
    mock_url = "http://#{mock_conf[:host]}:#{mock_conf[:port]}/"

    {:ok, %{mock_url: mock_url}}
  end

  test "supports basic third party resolver", %{mock_url: mock_url} do
    assert {:ok, %Consumer{
      id: "andrew",
      scope: "api:access"
    }} = ThirdPartyResolver.call_third_party_resolver(mock_url <> "auth/consumers/andrew")
  end

  test "supports mithril third party resolver", %{mock_url: mock_url} do
    assert {:ok, %Consumer{
      id: "bob",
      scope: "api:access"
    }} = ThirdPartyResolver.call_third_party_resolver(mock_url <> "auth/mithril/users/bob")
  end

  test "returns error on non-200 status codes" do
    assert {:error, :invalid_response}
      == ThirdPartyResolver.call_third_party_resolver("http://httpbin.org/status/418")
  end

  test "returns 422 status codes" do
    assert {:error, "API-KEY header is invalid."}
      == ThirdPartyResolver.parse_error_response(422, ~S({"error": {"message": "API-KEY header is invalid."}}))
  end

  test "returns 400 status codes" do
    assert {:error, :invalid_response}
      == ThirdPartyResolver.parse_error_response(400, "Invalid JSON")
  end

  test "returns error when third party is not available" do
    assert {:error, :unavailable}
      == ThirdPartyResolver.call_third_party_resolver("http://localhost:31001/")
  end

  test "returns error when response is not valid" do
    assert {:error, :invalid_response}
      == ThirdPartyResolver.call_third_party_resolver("http://httpbin.org/status/200")
    assert {:error, :invalid_response}
      = ThirdPartyResolver.call_third_party_resolver("http://httpbin.org/ip")
  end
end
