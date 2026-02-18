defmodule BlogWeb.Router do
  use BlogWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BlogWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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

    live_session :public, on_mount: [{BlogWeb.LocaleHook, :default}, BlogWeb.Hooks.MusicPlayer] do
      live "/", HomeLive, :index
      live "/posts/:slug", NoteLive, :show
      live "/about", AboutLive, :index
      live "/search", HomeLive, :search
      live "/list", HomeLive, :list
      live "/music/manage", MusicManageLive, :index
    end

    # Feed routes
    get "/rss.xml", FeedController, :rss
    get "/sitemap.xml", FeedController, :sitemap
    get "/robots.txt", FeedController, :robots
    get "/uploads/audio/*path", UploadController, :audio

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
