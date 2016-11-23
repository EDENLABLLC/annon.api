defmodule Gateway.Helpers.Pagination do
  @moduledoc """
  Functions related to paging
  """

  def page_info_from(params) do
    starting_after = extract_integer(params, "starting_after")
    ending_before = extract_integer(params, "ending_before")
    limit = extract_integer(params, "limit")

    cursors = %Ecto.Paging.Cursors{starting_after: starting_after, ending_before: ending_before}

    %Ecto.Paging{limit: limit, cursors: cursors}
  end

  def extract_integer(map, key) do
    case Map.get(map, key) do
      nil ->
        nil
      string ->
        case Integer.parse(string) do
          {integer, ""} -> integer
          _ -> string
        end
    end
  end
end
