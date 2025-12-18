defmodule BlogWeb.PageController do
  use BlogWeb, :live_view

  alias Blog.NoteData
  alias BlogWeb.Markdown
  alias BlogWeb.Scope
  alias BlogWeb.SEO

  @view_modes ~w(card compact)
  @recent_searches_max 3

  @impl true
  def render(assigns) do
    ~H"""
    <div id="home" class="px-4 pb-12 sm:px-8">
      <div class="flex flex-col gap-8 lg:grid lg:grid-cols-[minmax(0,1fr)_280px] lg:gap-12">
        <div class="space-y-6">
          <.header>
            <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p class="text-xs uppercase tracking-wide text-gray-500">Personal dev blog</p>

                <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100">
                  Notes & Experiments
                </h1>

                <p class="mt-1 text-sm font-medium text-gray-700 dark:text-gray-200">
                  Backend · Elixir · Phoenix · Infra
                </p>

                <p class="text-sm text-gray-600 dark:text-gray-300">
                  Short notes on building, shipping, and operating real-world systems — with code, tradeoffs, and
                  lessons learned.
                </p>

                <div class="mt-3 flex flex-wrap items-center gap-2">
                  <span class="rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-semibold text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-200">
                    Elixir
                  </span>
                  <span class="rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-semibold text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-200">
                    Phoenix
                  </span>
                  <span class="rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-semibold text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-200">
                    LiveView
                  </span>
                  <span class="rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-semibold text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-200">
                    Backend
                  </span>
                  <span class="rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-semibold text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-200">
                    Infra
                  </span>

                  <.link
                    navigate={~p"/about"}
                    class="ml-1 text-xs font-semibold text-gray-600 underline underline-offset-4 hover:text-gray-900 dark:text-gray-300 dark:hover:text-gray-100"
                  >
                    About →
                  </.link>
                </div>
              </div>

              <div class="flex w-full flex-col gap-2 sm:w-auto sm:flex-row sm:items-center sm:gap-3">
                <div class="relative w-full sm:w-80" id="global-search" phx-hook="RecentSearches">
                  <input
                    type="text"
                    id="search"
                    name="query"
                    value={@query}
                    placeholder="Search posts (Ctrl + K)"
                    autocomplete="off"
                    phx-debounce="250"
                    phx-keyup="update_input"
                    phx-change="update_input"
                    class="w-full rounded-full border border-gray-200 bg-gray-50 px-4 py-2 text-sm text-gray-800 shadow-sm outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-300 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-100"
                  />
                  <span class="pointer-events-none absolute inset-y-0 right-3 flex items-center gap-1 text-[11px] text-gray-500">
                    <kbd class="rounded bg-gray-200 px-1 dark:bg-gray-700">Ctrl</kbd> <span>+</span>
                    <kbd class="rounded bg-gray-200 px-1 dark:bg-gray-700">K</kbd>
                  </span>
                  <div
                    id="recent-searches-panel"
                    data-recent-searches-panel
                    phx-update="ignore"
                    class="absolute left-0 right-0 top-full mt-2 hidden overflow-hidden rounded-xl border border-gray-200 bg-white shadow-lg dark:border-gray-800 dark:bg-gray-950"
                  />
                </div>

                <div class="inline-flex w-full items-center justify-between gap-2 sm:w-auto sm:justify-start">
                  <div class="inline-flex rounded-xl bg-gray-100 p-1 dark:bg-gray-800">
                    <button
                      type="button"
                      phx-click="set_view_mode"
                      phx-value-mode="card"
                      aria-label="Card view"
                      class={[
                        "inline-flex items-center gap-1 rounded-lg px-2.5 py-1 text-xs font-semibold transition",
                        @view_mode == "card" &&
                          "bg-white text-indigo-700 shadow-sm dark:bg-gray-950 dark:text-indigo-200",
                        @view_mode != "card" &&
                          "text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-gray-100"
                      ]}
                    >
                      <.icon name="hero-squares-2x2-mini" class="h-4 w-4" /> Card
                    </button>
                    <button
                      type="button"
                      phx-click="set_view_mode"
                      phx-value-mode="compact"
                      aria-label="Compact view"
                      class={[
                        "inline-flex items-center gap-1 rounded-lg px-2.5 py-1 text-xs font-semibold transition",
                        @view_mode == "compact" &&
                          "bg-white text-indigo-700 shadow-sm dark:bg-gray-950 dark:text-indigo-200",
                        @view_mode != "compact" &&
                          "text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-gray-100"
                      ]}
                    >
                      <.icon name="hero-bars-3-bottom-left-mini" class="h-4 w-4" /> Compact
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </.header>

          <div class="flex flex-wrap items-center gap-2">
            <button
              class={[
                "rounded-full px-3 py-1 text-xs font-semibold transition-colors duration-150 motion-reduce:transition-none",
                @active_tag == "" && "bg-indigo-600 text-white",
                @active_tag != "" &&
                  "bg-gray-200 text-gray-800 hover:bg-gray-300 dark:bg-gray-800 dark:text-gray-100 dark:hover:bg-gray-700"
              ]}
              phx-click="filter_tag"
              phx-value-tag=""
            >
              All
            </button>

            <%= for tag <- @available_tags do %>
              <button
                class={[
                  "rounded-full px-3 py-1 text-xs font-semibold transition-colors duration-150 motion-reduce:transition-none",
                  @active_tag == tag &&
                    "bg-indigo-600 text-white shadow-sm ring-1 ring-indigo-600/30 dark:ring-indigo-400/30",
                  @active_tag != tag &&
                    "bg-gray-200 text-gray-800 hover:bg-gray-300 dark:bg-gray-800 dark:text-gray-100 dark:hover:bg-gray-700"
                ]}
                phx-click="filter_tag"
                phx-value-tag={tag}
              >
                <%= tag %>
              </button>
            <% end %>

            <button
              :if={@query != "" or @active_tag != ""}
              phx-click="clear_filters"
              class="rounded-full px-3 py-1 text-xs font-semibold text-gray-600 underline underline-offset-4 hover:text-gray-900 dark:text-gray-300"
            >
              Clear
            </button>
          </div>

          <div class="md:hidden">
            <details class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-gray-900">
              <summary class="cursor-pointer select-none text-sm font-semibold text-gray-800 dark:text-gray-100">
                Explore
              </summary>
              <div class="mt-3 space-y-3">
                <.context_widgets notes={@notes} active_tag={@active_tag} />
              </div>
            </details>
          </div>

          <%= if @view_mode == "compact" do %>
            <div class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
              <div class="divide-y divide-gray-200 dark:divide-gray-800">
                <%= for n <- @notes do %>
                  <.link navigate={~p"/posts/#{n.slug}"} class="block">
                    <div class="group flex items-center gap-3 px-3 py-2.5 hover:bg-gray-50 dark:hover:bg-gray-800/60">
                      <p class="min-w-0 flex-1 truncate text-sm font-semibold text-gray-900 group-hover:text-indigo-600 dark:text-gray-100">
                        <%= n.title_html || n.title %>
                      </p>

                      <div class="shrink-0 text-[11px] text-gray-500 dark:text-gray-400">
                        <span><%= format_date(n.inserted_at) %></span>
                        <span aria-hidden="true" class="mx-1">•</span>
                        <span><%= n.reading_time %> min</span>
                        <%= if n.scope_summary do %>
                          <span aria-hidden="true" class="mx-1">•</span>
                          <span class="text-gray-500 dark:text-gray-400"><%= n.scope_summary %></span>
                        <% end %>
                      </div>

                      <div class="hidden shrink-0 items-center justify-end gap-1 overflow-hidden md:flex">
                        <span
                          :for={tag <- Enum.take(n.tags, 3)}
                          class={[
                            "shrink-0 rounded-full px-2 py-0.5 text-[11px] font-semibold",
                            tag_emphasis?(tag, @query_tokens, @active_tag) &&
                              "bg-indigo-50 text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-200",
                            !tag_emphasis?(tag, @query_tokens, @active_tag) &&
                              "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-200"
                          ]}
                        >
                          <%= tag %>
                        </span>
                        <span
                          :if={length(n.tags) > 3}
                          class="shrink-0 rounded-full bg-gray-100 px-2 py-0.5 text-[11px] font-semibold text-gray-700 dark:bg-gray-800 dark:text-gray-200"
                        >
                          +<%= length(n.tags) - 3 %>
                        </span>
                      </div>
                    </div>
                  </.link>
                <% end %>
              </div>
            </div>
          <% else %>
            <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
              <%= for {n, index} <- Enum.with_index(@notes) do %>
                <.link navigate={~p"/posts/#{n.slug}"}>
                  <article class="group flex h-full flex-col overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm transition hover:-translate-y-0.5 hover:shadow-md motion-reduce:transition-none motion-reduce:transform-none dark:border-gray-800 dark:bg-gray-900">
                    <div class="aspect-[16/10] w-full overflow-hidden bg-gradient-to-br from-slate-200 to-slate-100 dark:from-slate-800 dark:to-slate-700">
                      <img
                        phx-track-static
                        src={n.image_path && ("/images/" <> n.image_path)}
                        alt={n.title}
                        width="400"
                        height="300"
                        loading={if index < 3, do: "eager", else: "lazy"}
                        fetchpriority={if index == 0, do: "high", else: "auto"}
                        decoding="async"
                        class="h-full w-full object-cover transition duration-300 group-hover:scale-105 motion-reduce:transition-none motion-reduce:transform-none"
                      />
                    </div>

                    <div class="flex flex-1 flex-col gap-2 p-3">
                      <div class="flex flex-wrap items-center gap-1.5">
                        <span class="inline-flex items-center rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                          <%= post_type_label(n) %>
                        </span>

                        <%= if difficulty = difficulty_label(n) do %>
                          <span class={[
                            "inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold",
                            difficulty_badge_classes(difficulty)
                          ]}>
                            <%= difficulty %>
                          </span>
                        <% end %>
                      </div>

                      <h2 class="text-lg font-bold leading-snug text-gray-900 transition group-hover:text-indigo-600 dark:text-gray-100">
                        <%= n.title_html || n.title %>
                      </h2>

                      <p class="line-clamp-2 text-sm leading-relaxed text-gray-600 dark:text-gray-300">
                        <%= n.excerpt_html || n.excerpt %>
                      </p>

                      <div class="mt-auto flex flex-col gap-2 pt-1">
                        <div class="flex items-center justify-between text-[11px] text-gray-500 dark:text-gray-400">
                          <span><%= format_date(n.inserted_at) %></span>
                          <span><%= n.reading_time %> min read</span>
                        </div>

                        <div :if={n.scopes != []} class="flex flex-wrap gap-1">
                          <span
                            :for={scope <- n.scopes}
                            class="rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-200"
                          >
                            <%= scope %>
                          </span>
                        </div>

                        <div :if={n.tags != []} class="flex flex-wrap gap-1">
                          <span
                            :for={tag <- Enum.take(n.tags, 4)}
                            class={[
                              "rounded-full px-2 py-0.5 text-[11px] font-semibold transition-colors duration-150 motion-reduce:transition-none",
                              tag_emphasis?(tag, @query_tokens, @active_tag) &&
                                "bg-indigo-50 text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-200",
                              !tag_emphasis?(tag, @query_tokens, @active_tag) &&
                                "bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-200 dark:hover:bg-gray-700"
                            ]}
                          >
                            <%= tag %>
                          </span>

                          <span
                            :if={length(n.tags) > 4}
                            class="rounded-full bg-gray-100 px-2 py-0.5 text-[11px] font-semibold text-gray-700 dark:bg-gray-800 dark:text-gray-200"
                          >
                            +<%= length(n.tags) - 4 %>
                          </span>
                        </div>
                      </div>
                    </div>
                  </article>
                </.link>
              <% end %>
            </div>
          <% end %>

          <div
            :if={@notes == []}
            class="rounded-xl border border-dashed border-gray-300 bg-gray-50 p-6 text-center text-sm text-gray-500 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
          >
            검색 결과가 없습니다. 검색어를 바꾸거나 태그 필터를 해제해 보세요.
          </div>
        </div>

        <aside class="hidden space-y-4 md:block lg:sticky lg:top-10">
          <.context_widgets notes={@notes} active_tag={@active_tag} />
          <.live_component module={BlogWeb.TimelinePanel} id="timeline-panel" current_note_id={nil} />
        </aside>
      </div>
    </div>
    """
  end

  attr :notes, :list, required: true
  attr :active_tag, :string, default: ""

  defp context_widgets(assigns) do
    pinned = pinned_post(assigns.notes)
    top_tags = top_tags(assigns.notes, 8)

    assigns =
      assigns
      |> assign(:pinned, pinned)
      |> assign(:top_tags, top_tags)

    ~H"""
    <div class="space-y-4">
      <section class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-gray-900">
        <p class="text-sm font-semibold text-gray-800 dark:text-gray-100">Who writes this?</p>
        <p class="mt-1 text-sm text-gray-600 dark:text-gray-300">
          A developer portfolio in blog form — notes from building backend systems with Elixir/Phoenix.
        </p>
        <.link
          navigate={~p"/about"}
          class="mt-3 inline-flex text-xs font-semibold text-gray-600 underline underline-offset-4 hover:text-gray-900 dark:text-gray-300 dark:hover:text-gray-100"
        >
          Read the About page →
        </.link>
      </section>

      <section
        :if={@pinned}
        class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-gray-900"
      >
        <div class="flex items-center justify-between">
          <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">Pinned</p>
          <p class="text-[11px] text-gray-500 dark:text-gray-400"><%= format_date(@pinned.inserted_at) %></p>
        </div>

        <.link navigate={~p"/posts/#{@pinned.slug}"} class="mt-2 block">
          <p class="text-sm font-semibold text-gray-900 hover:text-indigo-600 dark:text-gray-100">
            <%= @pinned.title %>
          </p>
          <p class="mt-1 line-clamp-2 text-sm text-gray-600 dark:text-gray-300">
            <%= @pinned.excerpt %>
          </p>
        </.link>
      </section>

      <section class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-gray-900">
        <div class="flex items-center justify-between">
          <p class="text-sm font-semibold text-gray-800 dark:text-gray-100">Topics</p>
          <.link
            navigate={~p"/rss.xml"}
            class="text-[11px] font-semibold text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100"
          >
            RSS
          </.link>
        </div>

        <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
          Top tags in the current view.
        </p>

        <div class="mt-3 flex flex-wrap gap-2">
          <button
            :for={{tag, count} <- @top_tags}
            type="button"
            phx-click="filter_tag"
            phx-value-tag={tag}
            class={[
              "inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold transition-colors duration-150 motion-reduce:transition-none",
              @active_tag == tag &&
                "bg-indigo-600 text-white",
              @active_tag != tag &&
                "bg-gray-200 text-gray-800 hover:bg-gray-300 dark:bg-gray-800 dark:text-gray-100 dark:hover:bg-gray-700"
            ]}
          >
            <span><%= tag %></span>
            <span class="text-[11px] opacity-80"><%= count %></span>
          </button>
        </div>

        <div class="mt-4 flex flex-wrap items-center gap-x-3 gap-y-2 text-xs font-semibold">
          <.link
            navigate={~p"/about"}
            class="text-gray-600 underline underline-offset-4 hover:text-gray-900 dark:text-gray-300 dark:hover:text-gray-100"
          >
            About
          </.link>
          <.link
            navigate={~p"/sitemap.xml"}
            class="text-gray-600 underline underline-offset-4 hover:text-gray-900 dark:text-gray-300 dark:hover:text-gray-100"
          >
            Sitemap
          </.link>
        </div>
      </section>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"remote_ip" => remote_ip}, socket) do
    notes = NoteData.list_notes()
    seo = SEO.seo_assigns(:blog, notes)

    # Get first post image for LCP preload
    first_note = List.first(notes)
    lcp_image = if first_note && first_note.image_path do
      "/images/#{first_note.image_path}"
    else
      nil
    end

    {:ok,
     socket
     |> assign(seo)
     |> assign(
       remote_ip: remote_ip,
       scope: %Scope{current_ip: remote_ip},
       query: "",
       active_tag: "",
       query_tokens: [],
       view_mode: "card",
       notes: decorate_notes(notes, [], ""),
       available_tags: NoteData.list_tags(),
       lcp_image: lcp_image
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    query = Map.get(params, "query", "") |> to_string() |> String.trim()
    tag = Map.get(params, "tag", "") |> to_string() |> String.trim()
    query_tokens = query_tokens(query)
    notes = NoteData.list_notes(%{query: query, tag: tag})

    {:noreply,
     assign(socket,
       query: query,
       active_tag: tag,
       query_tokens: query_tokens,
       notes: decorate_notes(notes, query_tokens, tag),
       available_tags: NoteData.list_tags(),
       recent_searches_max: @recent_searches_max
     )}
  end

  @impl true
  def handle_event("update_input", %{"value" => value}, socket) do
    value = value |> to_string() |> String.trim()
    {:noreply, push_patch(socket, to: list_path(value, socket.assigns.active_tag))}
  end

  def handle_event("update_input", %{"query" => value}, socket) do
    value = value |> to_string() |> String.trim()
    {:noreply, push_patch(socket, to: list_path(value, socket.assigns.active_tag))}
  end

  def handle_event("filter_tag", %{"tag" => tag}, socket) do
    {:noreply, push_patch(socket, to: list_path(socket.assigns.query, tag))}
  end

  def handle_event("set_view_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, sanitize_view_mode(mode))}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/")}
  end

  defp decorate_notes(notes, query_tokens, active_tag) do
    highlight_re = if query_tokens == [], do: nil, else: highlight_regex(query_tokens)

    Enum.map(notes, fn note ->
      content = note.raw_markdown || note.content
      excerpt_text = excerpt(content)
      tags = Markdown.tag_list(note.tags)

      scopes = match_scopes(note.title, content, tags, query_tokens, active_tag)

      %{
        id: note.id,
        slug: note.slug,
        title: note.title,
        title_html: highlight_html(note.title, highlight_re),
        excerpt: excerpt_text,
        excerpt_html: highlight_html(excerpt_text, highlight_re),
        tags: tags,
        categories: note.categories,
        image_path: note.image_path,
        inserted_at: note.inserted_at,
        reading_time: note.reading_time || Markdown.reading_time_minutes(content),
        scopes: scopes,
        scope_summary: scope_summary(scopes)
      }
    end)
  end

  defp excerpt(content) do
    content
    |> to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.slice(0, 140)
    |> case do
      text when byte_size(text) < 140 -> text
      text -> text <> "…"
    end
  end

  defp format_date(%DateTime{} = date), do: Calendar.strftime(date, "%Y-%m-%d")
  defp format_date(%NaiveDateTime{} = date), do: Calendar.strftime(date, "%Y-%m-%d")
  defp format_date(_), do: ""

  defp list_path("", ""), do: ~p"/"

  defp list_path(query, tag) do
    params =
      []
      |> maybe_param(:query, query)
      |> maybe_param(:tag, tag)

    ~p"/list?#{params}"
  end

  defp maybe_param(list, _key, ""), do: list
  defp maybe_param(list, key, value), do: Keyword.put(list, key, value)

  defp sanitize_view_mode(mode) when mode in @view_modes, do: mode
  defp sanitize_view_mode(_), do: "card"

  defp pinned_post(notes) do
    Enum.find(notes, &pinned_note?/1)
  end

  defp pinned_note?(%{tags: tags, categories: categories}) do
    tags = Enum.map(tags || [], &String.downcase(to_string(&1)))

    categories =
      categories
      |> to_string()
      |> String.downcase()
      |> String.split([",", ";", "|", " "], trim: true)

    "pinned" in tags or "pin" in tags or "pinned" in categories or "pin" in categories
  end

  defp pinned_note?(_), do: false

  defp top_tags(notes, limit) do
    notes
    |> Enum.flat_map(&(&1.tags || []))
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reject(&(String.downcase(&1) in ["pinned", "pin"]))
    |> Enum.frequencies()
    |> Enum.sort_by(fn {tag, count} -> {-count, String.downcase(tag)} end)
    |> Enum.take(limit)
  end

  defp query_tokens(query) do
    query
    |> to_string()
    |> String.trim()
    |> String.split(~r/\s+/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.downcase/1)
    |> Enum.filter(&(String.length(&1) >= 2))
    |> Enum.uniq()
    |> Enum.take(4)
  end

  defp highlight_html(_text, nil), do: nil

  defp highlight_html(text, regex) do
    text = to_string(text)

    parts = Regex.split(regex, text, include_captures: true, trim: false)

    html =
      parts
      |> Enum.map(fn part ->
        if Regex.match?(regex, part) do
          "<mark class=\"rounded bg-yellow-200/60 px-0.5 text-gray-900 dark:bg-yellow-300/20 dark:text-gray-100\">#{Phoenix.HTML.safe_to_string(Phoenix.HTML.html_escape(part))}</mark>"
        else
          Phoenix.HTML.safe_to_string(Phoenix.HTML.html_escape(part))
        end
      end)
      |> IO.iodata_to_binary()

    Phoenix.HTML.raw(html)
  end

  defp highlight_regex(tokens) do
    pattern =
      tokens
      |> Enum.map(&Regex.escape/1)
      |> Enum.join("|")

    Regex.compile!("(#{pattern})", "i")
  end

  defp match_scopes(title, content, tags, query_tokens, active_tag) do
    title = title |> to_string() |> String.downcase()
    content = content |> to_string() |> String.downcase()
    tags = Enum.map(tags || [], &(&1 |> to_string() |> String.downcase()))

    title_match? = query_tokens != [] and Enum.any?(query_tokens, &String.contains?(title, &1))

    content_match? =
      query_tokens != [] and Enum.any?(query_tokens, &String.contains?(content, &1))

    tag_match? =
      (active_tag != "" and Enum.any?(tags, &(&1 == String.downcase(active_tag)))) or
        (query_tokens != [] and Enum.any?(query_tokens, fn token -> Enum.any?(tags, &String.contains?(&1, token)) end))

    []
    |> maybe_add_scope(title_match?, "Title")
    |> maybe_add_scope(content_match?, "Content")
    |> maybe_add_scope(tag_match?, "Tag")
  end

  defp maybe_add_scope(list, true, label), do: list ++ [label]
  defp maybe_add_scope(list, false, _label), do: list

  defp scope_summary([]), do: nil

  defp scope_summary(scopes) do
    scopes
    |> Enum.map(fn
      "Title" -> "title"
      "Content" -> "content"
      "Tag" -> "tag"
      other -> other |> to_string() |> String.downcase()
    end)
    |> Enum.join("+")
  end

  defp tag_emphasis?(tag, query_tokens, active_tag) do
    tag = tag |> to_string() |> String.downcase()

    active? =
      active_tag != "" and tag == (active_tag |> to_string() |> String.downcase())

    active? or Enum.any?(query_tokens, fn token -> String.contains?(tag, token) end)
  end

  defp post_type_label(note) do
    tokens = post_meta_tokens(note)

    cond do
      "note" in tokens -> "Note"
      "post" in tokens -> "Post"
      true -> "Post"
    end
  end

  defp difficulty_label(note) do
    tokens = post_meta_tokens(note)

    cond do
      Enum.any?(tokens, &(&1 in ["beginner", "easy"])) -> "Beginner"
      Enum.any?(tokens, &(&1 in ["intermediate", "medium"])) -> "Intermediate"
      Enum.any?(tokens, &(&1 in ["advanced", "hard"])) -> "Advanced"
      true -> nil
    end
  end

  defp difficulty_badge_classes("Beginner"),
    do: "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-200"

  defp difficulty_badge_classes("Intermediate"),
    do: "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-200"

  defp difficulty_badge_classes("Advanced"),
    do: "bg-rose-100 text-rose-800 dark:bg-rose-900/30 dark:text-rose-200"

  defp difficulty_badge_classes(_),
    do: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-200"

  defp post_meta_tokens(note) do
    tags = (note.tags || []) |> Enum.map(&to_string/1)

    categories =
      note
      |> Map.get(:categories, "")
      |> to_string()
      |> String.split([",", ";", "|"], trim: true)

    (tags ++ categories)
    |> Enum.flat_map(fn token ->
      token
      |> to_string()
      |> String.downcase()
      |> String.split([":", "/", " "], trim: true)
    end)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end
end
