defmodule BlogWeb.LocalePlug do
  @moduledoc """
  Reads the `locale` cookie and puts it into the session
  so that LiveView on_mount hooks can read it.
  """

  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    conn = fetch_cookies(conn)
    locale = conn.cookies["locale"]

    if locale && locale in Blog.Translation.supported_languages() do
      put_session(conn, :locale, locale)
    else
      conn
    end
  end
end
