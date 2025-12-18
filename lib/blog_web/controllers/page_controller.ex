defmodule BlogWeb.PageController do
  use BlogWeb, :live_view

  alias Blog.NoteData
  alias BlogWeb.Markdown
  alias BlogWeb.Scope
  alias BlogWeb.SEO

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

                <p class="text-sm text-gray-600 dark:text-gray-300">
                  Search by title/content or filter by tags.
                </p>
              </div>

              <div class="relative w-full sm:w-80">
                <input
                  type="text"
                  id="search"
                  name="query"
                  value={@query}
                  placeholder="Search posts (Ctrl + K)"
                  phx-debounce="250"
                  phx-keyup="update_input"
                  phx-change="update_input"
                  class="w-full rounded-full border border-gray-200 bg-gray-50 px-4 py-2 text-sm text-gray-800 shadow-sm outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-300 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-100"
                />
                <span class="pointer-events-none absolute inset-y-0 right-3 flex items-center gap-1 text-[11px] text-gray-500">
                  <kbd class="rounded bg-gray-200 px-1 dark:bg-gray-700">Ctrl</kbd> <span>+</span>
                  <kbd class="rounded bg-gray-200 px-1 dark:bg-gray-700">K</kbd>
                </span>
              </div>
            </div>
          </.header>

          <div class="flex flex-wrap items-center gap-2">
            <button
              class={[
                "rounded-full px-3 py-1 text-xs font-semibold transition",
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
                  "rounded-full px-3 py-1 text-xs font-semibold transition",
                  @active_tag == tag && "bg-indigo-600 text-white",
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

          <div class="grid grid-cols-1 gap-5 md:grid-cols-2 lg:grid-cols-3">
            <%= for n <- @notes do %>
              <.link navigate={~p"/posts/#{n.slug}"}>
                <article class="group flex h-full flex-col overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm transition hover:-translate-y-1 hover:shadow-lg dark:border-gray-800 dark:bg-gray-900">
                  <div class="aspect-[4/3] w-full overflow-hidden bg-gradient-to-br from-slate-200 to-slate-100 dark:from-slate-800 dark:to-slate-700">
                    <img
                      phx-track-static
                      src={n.image_path && ~p"/images/#{n.image_path}"}
                      alt={n.title}
                      width="400"
                      height="300"
                      loading="lazy"
                      decoding="async"
                      class="h-full w-full object-cover transition duration-300 group-hover:scale-105"
                    />
                  </div>

                  <div class="flex flex-1 flex-col gap-3 p-4">
                    <div class="flex flex-wrap gap-2">
                      <span
                        :for={tag <- n.tags}
                        class="rounded-full bg-indigo-50 px-2 py-0.5 text-xs font-semibold text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-200"
                      >
                        <%= tag %>
                      </span>
                    </div>

                    <h2 class="text-lg font-bold text-gray-900 transition group-hover:text-indigo-600 dark:text-gray-100">
                      <%= n.title %>
                    </h2>

                    <p class="h-[84px] overflow-hidden text-sm leading-relaxed text-gray-600 dark:text-gray-300">
                      <%= n.excerpt %>
                    </p>

                    <div class="mt-auto flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
                      <span><%= format_date(n.inserted_at) %></span>
                      <span><%= n.reading_time %> min read</span>
                    </div>
                  </div>
                </article>
              </.link>
            <% end %>
          </div>

          <div
            :if={@notes == []}
            class="rounded-xl border border-dashed border-gray-300 bg-gray-50 p-6 text-center text-sm text-gray-500 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
          >
            검색 결과가 없습니다. 검색어를 바꾸거나 태그 필터를 해제해 보세요.
          </div>
        </div>

        <aside class="hidden md:block lg:sticky lg:top-10">
          <.live_component module={BlogWeb.TimelinePanel} id="timeline-panel" current_note_id={nil} />
        </aside>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"remote_ip" => remote_ip}, socket) do
    notes = NoteData.list_notes()
    seo = SEO.seo_assigns(:blog, notes)

    {:ok,
     socket
     |> assign(seo)
     |> assign(
       remote_ip: remote_ip,
       scope: %Scope{current_ip: remote_ip},
       query: "",
       active_tag: "",
       notes: decorate_notes(notes),
       available_tags: NoteData.list_tags()
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    query = Map.get(params, "query", "") |> to_string() |> String.trim()
    tag = Map.get(params, "tag", "") |> to_string() |> String.trim()
    notes = NoteData.list_notes(%{query: query, tag: tag})

    {:noreply,
     assign(socket,
       query: query,
       active_tag: tag,
       notes: decorate_notes(notes),
       available_tags: NoteData.list_tags()
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

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/")}
  end

  defp decorate_notes(notes) do
    Enum.map(notes, fn note ->
      %{
        id: note.id,
        slug: note.slug,
        title: note.title,
        excerpt: excerpt(note.raw_markdown || note.content),
        tags: Markdown.tag_list(note.tags),
        image_path: note.image_path,
        inserted_at: note.inserted_at,
        reading_time:
          note.reading_time || Markdown.reading_time_minutes(note.raw_markdown || note.content)
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
end
