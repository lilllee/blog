defmodule BlogWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :blog

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_blog_key",
    signing_salt: "+NOIaQyD",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug RemoteIp, headers: ["fly-client-ip"]
  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug :redirect_root_domain

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :blog,
    gzip: true,
    only: ~w(assets fonts images uploads music vendor favicon.ico robots.txt),
    cache_control_for_etags: "public, max-age=31536000, immutable",
    headers: [
      {"cache-control", "public, max-age=31536000, immutable"}
    ]

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader, otp_app: :blog
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug BlogWeb.Router

  defp redirect_root_domain(%Plug.Conn{host: "junho.me"} = conn, _opts) do
    location = redirect_location(conn, "https://blog.junho.me")

    conn
    |> Plug.Conn.put_resp_header("location", location)
    |> Plug.Conn.send_resp(301, "")
    |> Plug.Conn.halt()
  end

  defp redirect_root_domain(conn, _opts), do: conn

  defp redirect_location(conn, base) do
    path = conn.request_path || "/"

    case conn.query_string do
      "" -> base <> path
      qs -> base <> path <> "?" <> qs
    end
  end
end
