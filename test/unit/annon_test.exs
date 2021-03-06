defmodule AnnonTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "init/2 resolves :system tuples" do
    System.put_env("MY_TEST_ENV", "test_env_value")
    on_exit(fn ->
      System.delete_env("MY_TEST_ENV")
    end)

    assert {:ok, [
      my_conf: "test_env_value",
      other_conf: "persisted"
    ]} == Annon.init(nil, [my_conf: {:system, "MY_TEST_ENV"}, other_conf: "persisted"])
  end
end
