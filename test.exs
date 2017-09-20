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
  {"user-agent", ["Mozilla"]},
  {"content-type", ["application/xml"]},
  {"something", ["else"]}
]

headers2 = [
  {"user-agent", ["Mozilla"]},
  {"content-type", ["application/json"]}
]

headers3 = [
  {"user-agent", ["Chrome"]},
  {"content-type", ["application/xml"]}
]

headers4 = [
  {"user-agent", ["Chrome"]},
  {"content-type", ["application/json"]}
]

headers5 = [
  {"a", ["x"]},
  {"b", ["y"]}
]

headers6 = [
  {"user-agent", ["Internet Explorer"]}
]

Enum.each [headers1, headers2, headers3, headers4, headers5, headers6], fn headers ->
  check_fun = fn list ->
    for %{"name" => listed_name, "values" => listed_values} <- list,
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

  whitelisted = Enum.all? check_fun.(settings["whitelist"]), &(&1 == true)
  blacklisted = Enum.all? check_fun.(settings["blacklist"]), &(&1 == true)

  result = whitelisted || (whitelisted === nil && !blacklisted)

  IO.inspect result, label: "result"
end