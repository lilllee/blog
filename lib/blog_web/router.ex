defmodule BlogWeb.Router do
  use BlogWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BlogWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; " <>
          "script-src 'self' 'unsafe-inline' 'unsafe-eval'; " <>
          "style-src 'self' 'unsafe-inline'; " <>
          "img-src 'self' data: https:; " <>
          "connect-src 'self' wss:; " <>
          "font-src 'self'"
    }

    plug BlogWeb.LocalePlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin_auth do
    plug BlogWeb.AdminAuth
  end

  # Public routes
  scope "/", BlogWeb do
    pipe_through :browser

    live_session :public, on_mount: [{BlogWeb.LocaleHook, :default}] do
      live "/", HomeLive, :index
      live "/posts/:slug", NoteLive, :show
      live "/about", AboutLive, :index
    end

    # Feed routes
    get "/rss.xml", FeedController, :rss
    get "/sitemap.xml", FeedController, :sitemap
    get "/robots.txt", FeedController, :robots
    get "/images/uploads/*path", UploadController, :image

    # Legacy redirects
    get "/posts", RedirectController, :posts_index
    get "/notes/:id", RedirectController, :old_item_to_slug
    get "/item/:id", RedirectController, :old_item_to_slug
  end

  # Admin routes
  scope "/admin", BlogWeb.Admin do
    pipe_through [:browser, :admin_auth]

    live "/posts", PostIndexLive, :index
    live "/posts/new", PostEditLive, :new
    live "/posts/:id/edit", PostEditLive, :edit
    live "/about", AboutEditLive, :edit
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:blog, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BlogWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
