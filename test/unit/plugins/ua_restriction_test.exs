defmodule Annon.Plugins.UARestrictionTest do
  @moduledoc false
  use Annon.ConnCase, async: true
  alias Annon.Plugins.UARestriction

  @user_agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"

  describe "settings_validation_schema/3" do
    test "accepts valid config" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "blacklist" => [
          %{
            "name" => "user-agent",
            "values" => [@user_agent]
          }
        ],
        "whitelist" => [
          %{
            "name" => "user-agent",
            "values" => [@user_agent]
          }
        ]
      }}}

      assert %Ecto.Changeset{valid?: true} = UARestriction.validate_settings(changeset)

      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "whitelist" => [
          %{
            "name" => "user-agent",
            "values" => [@user_agent]
          }
        ]
      }}}

      assert %Ecto.Changeset{valid?: true} = UARestriction.validate_settings(changeset)

      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "blacklist" => [
          %{
            "name" => "user-agent",
            "values" => [@user_agent]
          }
        ]
      }}}

      assert %Ecto.Changeset{valid?: true} = UARestriction.validate_settings(changeset)
    end
  end

  describe "execute/3" do
    test "skips request when no user agent is present", %{conn: conn} do
      settings = %{
        "blacklist" => [
          %{
            "name" => "user-agent",
            "values" => ["Mozilla"]
          }
        ],
        "whitelist" => [
          %{
            "name" => "user-agent",
            "values" => ["Firefox"]
          }
        ]
      }

      assert conn == UARestriction.execute(conn, nil, settings)
    end

    test "blacklists user agents", %{conn: conn} do
      settings = %{
        "blacklist" => [
          %{
            "name" => "user-agent",
            "values" => ["Mozilla"]
          }
        ],
        "whitelist" => [
          %{
            "name" => "user-agent",
            "values" => ["Firefox"]
          }
        ]
      }

      assert %{
        "error" => %{
          "message" => "You has been blocked from accessing this resource",
          "type" => "forbidden"
        }
      } = conn
      |> Conn.put_req_header("user-agent", @user_agent)
      |> UARestriction.execute(nil, settings)
      |> json_response(403)
    end

    test "whitelists user agents", %{conn: conn} do
      settings = %{
        "blacklist" => [
          %{
            "name" => "user-agent",
            "values" => ["Mozilla"]
          }
        ],
        "whitelist" => [
          %{
            "name" => "user-agent",
            "values" => ["Chrome"]
          }
        ]
      }

      conn = Conn.put_req_header(conn, "user-agent", @user_agent)
      assert conn == UARestriction.execute(conn, nil, settings)

      settings = %{
        "blacklist" => ["Moz.*"],
        "whitelist" => ["Chr.*"],
      }

      conn = Conn.put_req_header(conn, "user-agent", @user_agent)
      assert conn == UARestriction.execute(conn, nil, settings)
    end

    test "works correctly on different combinations", %{conn: conn} do
      settings = %{
        "blacklist" => [
          %{
            "name" => "user-agent",
            "values" => ["Mozilla"]
          },
          %{
            "name" => "content-type",
            "values" => ["application/xml"]
          }
        ],
        "whitelist" => [
          %{
            "name" => "user-agent",
            "values" => ["Chrome", "Chromium"]
          },
          %{
            "name" => "content-type",
            "values" => ["application/json"]
          },
          %{
            "name" => "another_rule",
            "values" => ["a", "b", "c"]
          }
        ]
      }

      headers1 = [
        {"user-agent", "Mozilla"},
        {"content-type", "application/xml"},
        {"something", "else"}
      ]

      headers2 = [
        {"user-agent", "Mozilla"},
        {"content-type", "application/json"}
      ]

      headers3 = [
        {"user-agent", "Chrome"},
        {"content-type", "application/xml"}
      ]

      headers4 = [
        {"user-agent", "Chrome"},
        {"content-type", "application/json"}
      ]

      headers5 = [
        {"a", "x"},
        {"b", "y"}
      ]

      headers6 = [
        {"user-agent", "Internet Explorer"}
      ]

      Enum.each [headers1, headers2, headers3, headers6], fn headers ->
        conn =
          Enum.reduce headers, conn, fn {name, value}, conn ->
            Conn.put_req_header(conn, name, value)
          end

        assert %{
          "error" => %{
            "message" => "You has been blocked from accessing this resource",
            "type" => "forbidden"
          }
        } = conn
        |> UARestriction.execute(nil, settings)
        |> json_response(403)
      end

      Enum.each [headers4, headers5], fn headers ->
        conn =
          Enum.reduce headers, conn, fn {name, value}, conn ->
            Conn.put_req_header(conn, name, value)
          end

        assert conn == UARestriction.execute(conn, nil, settings)
      end
    end
  end
end
