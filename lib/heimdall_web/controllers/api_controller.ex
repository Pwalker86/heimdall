defmodule HeimdallWeb.ApiController do
  use HeimdallWeb, :controller
  import Plug.Conn
  require Integer


  # this route takes one upc, and returns the upc with the check digit added
  # http://0.0.0.0:4000/api/add_check_digit/1234
  def add_check_digit(conn, params) do
    check_digit_with_upc = _calculate_check_digit(params["upc"])
    _send_json(conn, 200, check_digit_with_upc)
  end

  # this route takes a comma separated list and should add a check digit to each element
  # http://0.0.0.0:4000/api/add_a_bunch_of_check_digits/12345,233454,34341432
  def add_a_bunch_of_check_digits(conn, params) do
    check_digits_with_upc = String.split(params["upcs"], ",")
    |> Enum.map((fn upc -> _calculate_check_digit(upc) end))

    _send_json(conn, 200, check_digits_with_upc)
  end

  # these are private methods
  defp _calculate_check_digit(upc) do
    odd_positions = String.graphemes(upc)
                    |> Enum.with_index(1)
                    |> Enum.map(fn(x) -> _get_odd_positions(x) end )
                    |> Enum.filter(fn(x) -> x != "" end )
                    |> Enum.map(fn(x) -> String.to_integer(x) end )
                    |> Enum.sum

    even_positions = String.graphemes(upc)
                     |> Enum.with_index(1)
                     |> Enum.map(fn(x) -> _get_even_positions(x) end )
                     |> Enum.filter(fn(x) -> x != "" end )
                     |> Enum.map(fn(x) -> String.to_integer(x) end )
                     |> Enum.sum
    # I know I could have probably used `Enum.reduce`, but I prefer a slightly more verbose approach for clarity.

    check_digit = ( odd_positions * 3 )
                  |> + even_positions
                  |> rem(10)
                  |> _get_remainder

    upc <> Integer.to_string(check_digit)
  end

  defp _get_remainder(remainder) do
    case remainder do
      0 -> 0
      _ -> 10 - remainder
    end
  end

  defp _get_odd_positions(tuple) do
    case Integer.is_odd(elem(tuple, 1)) do
      true -> elem(tuple, 0)
      _ -> ""
    end
  end

  defp _get_even_positions(tuple) do
    case Integer.is_even(elem(tuple, 1)) do
      true -> elem(tuple, 0)
      _ -> ""
    end
  end
  # I feel like these odd/even functions should be able to be combined with some pattern matching,
  # I'd to get some feedback from someone with more Elixir experience about this.

  # this is a thing to format your responses and return json to the client
  defp _send_json(conn, status, body) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(status, Poison.encode!(body))
  end

end
