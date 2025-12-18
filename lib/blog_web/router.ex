defmodule BlogWeb.Router do
  use BlogWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BlogWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_user_ip_to_session
  end

  defp put_user_ip_to_session(conn, _) do
    remote_ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    put_session(conn, :remote_ip, remote_ip)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin_auth do
    plug BlogWeb.AdminAuth
  end

  # get, post, 등 보다 더 많은 HTTP 메소드를 지원하는 live macro를 사용한다.
  # 사용하면 페이지의 특정 상태를 기반으로 UI가 즉각적으로 업데이트되기 때문에
  # get이나 post 방식의 요청보다 더 동적인 상호작용 가능

  scope "/", BlogWeb do
    pipe_through :browser

    live "/", PageController, :home
    live "/list", PageController, :list

    # New slug-based URL
    live "/posts/:slug", NoteLive, :show

    # 301 redirect from old ID-based URL to new slug-based URL
    get "/item/:id", RedirectController, :old_item_to_slug

    get "/rss.xml", FeedController, :rss
    get "/sitemap.xml", FeedController, :sitemap
    get "/robots.txt", FeedController, :robots
    live "/about", AboutLive, :index
    # live "/add", PageController, :add
    # live "/list/:sort", PageController, :list
    # live "/logs", LogLive, :logs
    # live "/chats", ChatLive, :chat
  end

  scope "/admin", BlogWeb do
    pipe_through [:browser, :admin_auth]

    live "/posts", Admin.PostIndexLive, :index
    live "/posts/new", Admin.PostEditLive, :new
    live "/posts/:id/edit", Admin.PostEditLive, :edit
    live "/about", Admin.AboutEditLive, :edit
    # live "/about", AboutLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", BlogWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:blog, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BlogWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
