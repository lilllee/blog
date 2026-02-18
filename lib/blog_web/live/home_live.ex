defmodule BlogWeb.HomeLive do
  use BlogWeb, :live_view

  alias Blog.NoteData
  alias Blog.Translation
  alias BlogWeb.SEO

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Hero section --%>
      <section class="pb-16">
        <h1 class="text-4xl font-bold tracking-tight text-foreground text-balance leading-tight">
          JunHo's Blog
        </h1>
        <p class="mt-6 text-base leading-relaxed text-muted-foreground text-pretty">
          <%= Translation.t("subtitle", @locale) %>
        </p>
      </section>

      <%!-- Section header with tag filter --%>
      <section class="pb-6 border-b border-border">
        <div class="flex items-center justify-between">
          <h2 class="text-xs font-semibold uppercase tracking-wider text-muted-foreground/60">
            <%= Translation.t("recent_posts", @locale) %>
          </h2>
          <div class="flex items-center gap-2 overflow-x-auto pb-1" role="tablist">
            <button
              phx-click="filter_tag"
              phx-value-tag=""
              role="tab"
              aria-selected={@selected_tag == ""}
              class={[
                "rounded-full px-3.5 py-1.5 text-xs font-medium transition-colors whitespace-nowrap",
                if(@selected_tag == "",
                  do: "bg-foreground text-background",
                  else:
                    "border border-border bg-secondary text-muted-foreground hover:bg-accent hover:text-foreground"
                )
              ]}
            >
              <%= Translation.t("all", @locale) %>
            </button>
            <button
              :for={tag <- @all_tags}
              phx-click="filter_tag"
              phx-value-tag={tag}
              role="tab"
              aria-selected={@selected_tag == tag}
              class={[
                "rounded-full px-3.5 py-1.5 text-xs font-medium transition-colors whitespace-nowrap",
                if(@selected_tag == tag,
                  do: "bg-foreground text-background",
                  else:
                    "border border-border bg-secondary text-muted-foreground hover:bg-accent hover:text-foreground"
                )
              ]}
            >
              <%= tag %>
            </button>
          </div>
        </div>
      </section>

      <%!-- Post list --%>
      <div class="mt-6">
        <article :for={post <- @posts} class="group">
          <.link
            navigate={~p"/posts/#{post.slug}"}
            class="block -mx-3 px-3 py-6 rounded-lg transition-colors card-hover border-b border-border last:border-b-0"
          >
            <div class="flex gap-4">
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2.5 min-h-[20px]">
                  <time class="text-xs font-medium tracking-wide text-muted-foreground/70">
                    <%= format_date(post.published_at || post.inserted_at) %>
                  </time>
                  <span :if={first_tag(post.tags)} class="text-muted-foreground/30">/</span>
                  <span
                    :if={first_tag(post.tags)}
                    class="text-xs font-medium text-muted-foreground/70"
                  >
                    <%= first_tag(post.tags) %>
                  </span>
                </div>
                <h3 class="mt-2 text-lg font-semibold leading-snug text-foreground transition-colors text-balance">
                  <%= post.title %>
                </h3>
                <p class="mt-2 text-sm leading-relaxed text-muted-foreground text-pretty line-clamp-2">
                  <%= excerpt(post.content || post.raw_markdown) %>
                </p>
              </div>
              <div :if={post.image_path} class="hidden sm:block flex-shrink-0 mt-1">
                <img
                  src={"/images/" <> post.image_path}
                  alt={post.title}
                  width="112"
                  height="80"
                  class="h-20 w-28 rounded-md object-cover"
                  loading="lazy"
                />
              </div>
            </div>
          </.link>
        </article>
      </div>

      <%!-- Empty state --%>
      <div :if={@posts == []} class="py-16 text-center">
        <p class="text-sm text-muted-foreground"><%= Translation.t("no_posts_yet", @locale) %></p>
      </div>
    </div>
    """
  end

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
        selected_tag: ""
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
    tags
    |> String.split(",", trim: true)
    |> List.first()
    |> case do
      nil -> nil
      tag -> String.trim(tag)
    end
  end

  defp first_tag(_), do: nil

  defp excerpt(nil), do: ""

  defp excerpt(content) do
    content
    |> String.replace(~r/[#*`\[\]()>_~\-]/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.slice(0, 200)
  end
end
