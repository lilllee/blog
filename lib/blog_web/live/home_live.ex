defmodule BlogWeb.HomeLive do
  use BlogWeb, :live_view

  alias Blog.NoteData
  alias Blog.Translation
  alias BlogWeb.SEO

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <header class="masthead">
        <p class="name">
          junho
          <.link navigate={~p"/about"} class="about-link">about</.link>
        </p>
        <p class="blurb"><%= Translation.t("subtitle", @locale) %></p>
      </header>

      <ul :if={@posts != []} class="list">
        <li :for={post <- @posts}>
          <.link navigate={~p"/posts/#{post.slug}"} class="entry">
            <span class="date"><%= format_date(post.published_at || post.inserted_at) %></span>
            <span class="title"><%= post.title %></span>
            <span :if={excerpt(post) != ""} class="excerpt"><%= excerpt(post) %></span>
          </.link>
        </li>
      </ul>

      <p :if={@posts == []} style="color: var(--muted); margin-top: 24px;">
        <%= Translation.t("no_posts_yet", @locale) %>
      </p>

      <footer class="qfooter">
        <span>© <%= DateTime.utc_now().year %> junho</span>
        <span class="langs">
          <.lang_links locale={@locale} />
          <.link navigate={~p"/admin/posts"} class="admin-link">admin</.link>
        </span>
      </footer>
    </section>
    """
  end

  attr :locale, :string, required: true

  defp lang_links(assigns) do
    ~H"""
    <button
      :for={code <- ~w(ko en ja zh)}
      type="button"
      phx-click="set_locale"
      phx-value-locale={code}
      class={if @locale == code, do: "current"}
    ><%= lang_label(code) %></button>
    """
  end

  defp lang_label("ko"), do: "한국어"
  defp lang_label("en"), do: "English"
  defp lang_label("ja"), do: "日本語"
  defp lang_label("zh"), do: "中文"

  @impl true
  def mount(_params, _session, socket) do
    locale = socket.assigns[:locale] || "ko"
    posts = NoteData.list_notes()

    seo =
      SEO.seo_assigns(:blog, posts,
        title: "junho",
        description: Translation.t("subtitle", locale)
      )

    socket =
      socket
      |> assign(seo)
      |> assign(posts: posts, original_posts: posts)

    if locale != "ko" and connected?(socket) do
      send(self(), {:translate_posts, locale})
    end

    {:ok, socket}
  end

  @impl true
  def handle_info({:locale_changed, locale}, socket) do
    if locale == "ko" do
      {:noreply, assign(socket, posts: socket.assigns.original_posts)}
    else
      send(self(), {:translate_posts, locale})
      {:noreply, socket}
    end
  end

  def handle_info({:translate_posts, locale}, socket) do
    posts = socket.assigns.original_posts
    pid = self()

    Task.start(fn ->
      translated =
        Enum.map(posts, fn post ->
          case Translation.translate(post.title, locale) do
            {:ok, t} when is_binary(t) -> %{post | title: t}
            _ -> post
          end
        end)

      send(pid, {:posts_translated, translated, locale})
    end)

    {:noreply, socket}
  end

  def handle_info({:posts_translated, translated, locale}, socket) do
    if socket.assigns[:locale] == locale do
      {:noreply, assign(socket, posts: translated)}
    else
      {:noreply, socket}
    end
  end

  defp format_date(%DateTime{} = d), do: Calendar.strftime(d, "%Y.%m.%d")
  defp format_date(%NaiveDateTime{} = d), do: Calendar.strftime(d, "%Y.%m.%d")
  defp format_date(_), do: ""

  defp excerpt(post) do
    (post.raw_markdown || post.content || "")
    |> String.replace(~r/!\[.*?\]\(.*?\)/, "")
    |> String.replace(~r/\[([^\]]*)\]\([^\)]*\)/, "\\1")
    |> String.replace(~r/[#*`>_~\-|]/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.slice(0, 140)
  end
end
