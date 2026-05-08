defmodule BlogWeb.HomeLive do
  use BlogWeb, :live_view

  alias Blog.NoteData
  alias Blog.Translation
  alias BlogWeb.Markdown
  alias BlogWeb.SEO

  @banner """
     _                   _           _     _
    (_)_   _ _ __ ___  | |__   ___ | |__ | | ___   __ _
    | | | | | '_ ` _ \\ | '_ \\ / _ \\| '_ \\| |/ _ \\ / _` |
    | | |_| | | | | | || |_) | (_) | |_) | | (_) | (_| |
   _/ |\\__,_|_| |_| |_||_.__/ \\___/|_.__/|_|\\___/ \\__, |
  |__/                                            |___/
  """

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- $ cat README.md --%>
      <section class="pt-8 pb-2">
        <.prompt cwd="~/blog" cmd="cat README.md" />
      </section>

      <section class="pb-7 text-muted-foreground">
        <pre class="tm-banner mb-4"><%= @banner %></pre>
        <div class="text-foreground"># <%= Translation.t("blog", @locale) %></div>
        <div class="py-1.5"></div>
        <p class="text-foreground/90 leading-relaxed">
          <%= Translation.t("subtitle", @locale) %>
        </p>
        <div class="py-1.5"></div>
        <div>
          → <%= @post_count %> posts
          <span class="text-muted-foreground/60"> · 한국어 / English</span>
        </div>
      </section>

      <%!-- $ ls posts/ --tag= --%>
      <section class="pt-2 pb-3">
        <.prompt cwd="~/blog" cmd={"ls posts/ --tag=" <> active_tag_label(@selected_tag)} />
      </section>

      <%!-- Filter row --%>
      <section
        class="flex items-center gap-3 flex-wrap py-3 border-y border-dashed border-border"
        role="tablist"
      >
        <span class="text-xs text-muted-foreground">filter:</span>
        <button
          phx-click="filter_tag"
          phx-value-tag=""
          role="tab"
          aria-selected={@selected_tag == ""}
          class={tag_button_class(@selected_tag == "")}
        >
          all
        </button>
        <button
          :for={tag <- @all_tags}
          phx-click="filter_tag"
          phx-value-tag={tag}
          role="tab"
          aria-selected={@selected_tag == tag}
          class={tag_button_class(@selected_tag == tag)}
        >
          <%= String.downcase(tag) %>
        </button>
      </section>

      <%!-- ls header --%>
      <div class="grid grid-cols-[100px_70px_56px_1fr] gap-4 pt-5 pb-2 border-b border-border text-[11px] uppercase tracking-[0.1em] text-muted-foreground">
        <span>DATE</span>
        <span>TAG</span>
        <span class="text-right">READ</span>
        <span>FILE</span>
      </div>

      <%!-- ls rows --%>
      <div :if={@posts != []}>
        <.link
          :for={post <- @posts}
          navigate={~p"/posts/#{post.slug}"}
          class="tm-row grid grid-cols-[100px_70px_56px_1fr] gap-4 py-3.5 border-b border-dashed border-border items-baseline -mx-3 px-3"
        >
          <span class="text-xs text-muted-foreground">
            <%= format_date(post.published_at || post.inserted_at) %>
          </span>
          <span class="text-xs text-tm-blue">
            <%= post.tags |> first_tag() |> String.downcase() %>
          </span>
          <span class="text-xs text-muted-foreground text-right">
            <%= reading_time(post) %>m
          </span>
          <div class="min-w-0">
            <div class="text-sm font-medium text-foreground truncate">
              <span class="text-tm-accent">▸</span> <%= post.title %>
            </div>
            <div class="mt-1 text-xs text-muted-foreground leading-snug line-clamp-2">
              <%= excerpt(post.content || post.raw_markdown) %>
            </div>
          </div>
        </.link>
      </div>

      <%!-- Empty state --%>
      <div :if={@posts == []} class="py-16 text-center text-muted-foreground">
        <p>$ ls posts/ — <%= Translation.t("no_posts_yet", @locale) %></p>
      </div>

      <%!-- Footer summary --%>
      <div :if={@posts != []} class="pt-5 pb-3 text-xs text-muted-foreground">
        → <%= length(@posts) %> files · <%= total_reading_time(@posts) %> minutes total
      </div>
    </div>
    """
  end

  attr :cwd, :string, required: true
  attr :cmd, :string, required: true

  defp prompt(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center gap-2.5 text-sm">
      <span class="text-tm-accent">junho</span>
      <span class="text-tm-blue"><%= @cwd %></span>
      <span class="text-muted-foreground">$</span>
      <span class="text-foreground"><%= @cmd %></span>
    </div>
    """
  end

  defp tag_button_class(active?) do
    base =
      "px-2 py-0.5 text-xs border rounded-none font-mono transition-colors hover:text-foreground"

    if active? do
      base <> " border-[var(--tm-accent)] text-tm-accent"
    else
      base <> " border-border bg-transparent text-muted-foreground"
    end
  end

  defp active_tag_label(""), do: "all"
  defp active_tag_label(tag), do: String.downcase(tag)

  @impl true
  def mount(_params, _session, socket) do
    locale = socket.assigns[:locale] || "ko"
    all_tags = NoteData.list_tags()
    posts = NoteData.list_notes()

    seo =
      SEO.seo_assigns(:blog, posts,
        title: "JunHo's Blog",
        description: Translation.t("subtitle", locale)
      )

    socket =
      socket
      |> assign(seo)
      |> assign(
        posts: posts,
        original_posts: posts,
        all_tags: all_tags,
        selected_tag: "",
        post_count: length(posts),
        banner: @banner
      )

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
          translated_title =
            case Translation.translate(post.title, locale) do
              {:ok, t} when is_binary(t) -> t
              _ -> post.title
            end

          %{post | title: translated_title}
        end)

      send(pid, {:posts_translated, translated, locale})
    end)

    {:noreply, socket}
  end

  def handle_info({:posts_translated, translated_posts, locale}, socket) do
    if socket.assigns[:locale] == locale do
      {:noreply, assign(socket, posts: translated_posts)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("filter_tag", %{"tag" => tag}, socket) do
    tag = String.trim(tag)
    locale = socket.assigns[:locale] || "ko"

    posts =
      if tag == "" do
        NoteData.list_notes()
      else
        NoteData.list_notes(%{tag: tag})
      end

    socket = assign(socket, original_posts: posts, posts: posts, selected_tag: tag)

    if locale != "ko" do
      send(self(), {:translate_posts, locale})
    end

    {:noreply, socket}
  end

  defp format_date(%DateTime{} = date), do: Calendar.strftime(date, "%Y.%m.%d")
  defp format_date(%NaiveDateTime{} = date), do: Calendar.strftime(date, "%Y.%m.%d")
  defp format_date(_), do: ""

  defp first_tag(tags) when is_binary(tags) do
    case tags |> String.split(",", trim: true) |> List.first() do
      nil -> ""
      tag -> String.trim(tag)
    end
  end

  defp first_tag(_), do: ""

  defp reading_time(%{reading_time: rt}) when is_integer(rt) and rt > 0, do: rt

  defp reading_time(post) do
    Markdown.reading_time_minutes(post.raw_markdown || post.content || "")
  end

  defp total_reading_time(posts), do: posts |> Enum.map(&reading_time/1) |> Enum.sum()

  defp excerpt(nil), do: ""

  defp excerpt(content) do
    content
    |> String.replace(~r/[#*`\[\]()>_~\-]/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.slice(0, 200)
  end
end
