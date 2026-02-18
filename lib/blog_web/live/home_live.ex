defmodule BlogWeb.HomeLive do
  use BlogWeb, :live_view

  alias Blog.NoteData
  alias Blog.Translation

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
                  else: "border border-border bg-secondary text-muted-foreground hover:bg-accent hover:text-foreground"
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
                  else: "border border-border bg-secondary text-muted-foreground hover:bg-accent hover:text-foreground"
                )
              ]}
            >
              <%= tag %>
            </button>
          </div>
        </div>
      </section>

      <%!-- Post list --%>
      <div class="mt-6 divide-y divide-border">
        <article :for={post <- @posts} class="group py-6 first:pt-0">
          <.link navigate={~p"/posts/#{post.slug}"} class="block -mx-3 px-3 py-1 rounded-lg transition-colors hover:bg-muted">
            <div class="flex gap-4">
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2.5 min-h-[20px]">
                  <time class="text-xs font-medium tracking-wide text-muted-foreground/70">
                    <%= format_date(post.published_at || post.inserted_at) %>
                  </time>
                  <span :if={first_tag(post.tags)} class="text-muted-foreground/30">/</span>
                  <span :if={first_tag(post.tags)} class="text-xs font-medium text-muted-foreground/70">
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
                  alt=""
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
    all_tags = NoteData.list_tags()
    posts = NoteData.list_notes()

    {:ok,
     assign(socket,
       posts: posts,
       all_tags: all_tags,
       selected_tag: "",
       page_title: "JunHo's Blog",
       meta: %{
         title: "JunHo's Blog",
         description: "개발, 일상, 그리고 생각을 기록합니다.",
         og_title: "JunHo's Blog",
         og_description: "개발, 일상, 그리고 생각을 기록합니다.",
         og_type: "website"
       }
     )}
  end

  @impl true
  def handle_info({:locale_changed, _locale}, socket), do: {:noreply, socket}

  @impl true
  def handle_event("filter_tag", %{"tag" => tag}, socket) do
    tag = String.trim(tag)

    posts =
      if tag == "" do
        NoteData.list_notes()
      else
        NoteData.list_notes(%{tag: tag})
      end

    {:noreply, assign(socket, posts: posts, selected_tag: tag)}
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
