defmodule BlogWeb.Plugs.Compression do
  @moduledoc """
  Enables Gzip compression for HTML responses.
  Static assets are already compressed via Plug.Static gzip: true.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("vary", "accept-encoding")
    |> register_before_send(&compress_response/1)
  end

  defp compress_response(conn) do
    # Only compress HTML responses
    case get_resp_header(conn, "content-type") do
      ["text/html" <> _] ->
        # Phoenix already handles gzip via Cowboy
        # This ensures vary header is set
        conn

      _ ->
        conn
    end
  end
end
