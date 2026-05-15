defmodule BlogWeb.AdminAuth do
  @moduledoc """
  HTTP Basic Auth for `/admin/*`.

  Credentials come from the `BLOG_ADMIN_USER` / `BLOG_ADMIN_PASS` env vars
  (loaded from `.env` in dev/test by `config/runtime.exs`, or set directly
  in production).
  """

  import Plug.Conn

  @realm "Admin"

  def init(opts), do: opts

  def call(conn, _opts) do
    username =
      System.get_env("BLOG_ADMIN_USER") ||
        raise "BLOG_ADMIN_USER environment variable is required"

    password =
      System.get_env("BLOG_ADMIN_PASS") ||
        raise "BLOG_ADMIN_PASS environment variable is required"

    case Plug.BasicAuth.parse_basic_auth(conn) do
      {^username, ^password} ->
        conn

      _ ->
        conn
        |> Plug.BasicAuth.request_basic_auth(realm: @realm)
        |> halt()
    end
  end
end
