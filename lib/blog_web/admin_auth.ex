defmodule BlogWeb.AdminAuth do
  import Plug.Conn

  @realm "Admin"
  @max_attempts 5
  @window_ms 300_000

  def init(opts), do: opts

  def call(conn, _opts) do
    ip = remote_ip_string(conn)

    if rate_limited?(ip) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(429, "Too Many Requests. Try again later.")
      |> halt()
    else
      do_auth(conn, ip)
    end
  end

  defp do_auth(conn, ip) do
    username =
      System.get_env("BLOG_ADMIN_USER") ||
        raise "BLOG_ADMIN_USER environment variable is required"

    password =
      System.get_env("BLOG_ADMIN_PASS") ||
        raise "BLOG_ADMIN_PASS environment variable is required"

    case Plug.BasicAuth.parse_basic_auth(conn) do
      {^username, ^password} ->
        clear_attempts(ip)
        conn

      _ ->
        record_attempt(ip)

        conn
        |> Plug.BasicAuth.request_basic_auth(realm: @realm)
        |> halt()
    end
  end

  defp remote_ip_string(conn) do
    conn.remote_ip |> :inet.ntoa() |> to_string()
  end

  defp rate_limited?(ip) do
    key = "admin_auth:#{ip}"

    case :ets.lookup(:rate_limit, key) do
      [{^key, count, first_attempt}] when count >= @max_attempts ->
        if System.monotonic_time(:millisecond) - first_attempt < @window_ms do
          true
        else
          :ets.delete(:rate_limit, key)
          false
        end

      _ ->
        false
    end
  end

  defp record_attempt(ip) do
    key = "admin_auth:#{ip}"
    now = System.monotonic_time(:millisecond)

    case :ets.lookup(:rate_limit, key) do
      [{^key, count, first_attempt}] ->
        if now - first_attempt < @window_ms do
          :ets.insert(:rate_limit, {key, count + 1, first_attempt})
        else
          :ets.insert(:rate_limit, {key, 1, now})
        end

      [] ->
        :ets.insert(:rate_limit, {key, 1, now})
    end
  end

  defp clear_attempts(ip) do
    :ets.delete(:rate_limit, "admin_auth:#{ip}")
  end
end
