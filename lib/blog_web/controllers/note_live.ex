defmodule BlogWeb.NoteLive do
  use BlogWeb, :live_view

  alias Blog.NoteData
  alias BlogWeb.Markdown
  alias BlogWeb.SEO

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 pb-16 sm:px-8">
      <div class="mb-6 flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400">
        <.link navigate={~p"/"} class="hover:text-indigo-600">Home</.link> <span>/</span>
        <span><%= @title %></span>
      </div>

      <%= if @note do %>
        <div class="flex flex-col gap-8 lg:grid lg:grid-cols-[minmax(0,1fr)_280px] lg:gap-12">
          <div class="space-y-6">
            <div class="space-y-3">
              <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100"><%= @title %></h1>

              <div class="flex flex-wrap items-center gap-3 text-sm text-gray-600 dark:text-gray-300">
                <span><%= @published_on %></span> <span>•</span>
                <span><%= @reading_time %> min read</span>
                <span
                  :for={tag <- @tags}
                  class="rounded-full bg-indigo-50 px-2 py-0.5 text-xs font-semibold text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-100"
                >
                  <%= tag %>
                </span>
              </div>
            </div>

            <div
              :if={@image_path}
              class="overflow-hidden rounded-2xl border border-gray-200 shadow-sm dark:border-gray-800"
            >
              <img
                phx-track-static
                src={"/images/" <> @image_path}
                alt={@title}
                width="980"
                height="288"
                loading="eager"
                fetchpriority="high"
                decoding="async"
                class="h-72 w-full object-cover"
              />
            </div>

            <article class="markdown-body prose prose-slate max-w-none dark:prose-invert">
              <%= @content_html %>
            </article>

            <section
              :if={@series_prev || @series_next}
              class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-gray-900"
            >
              <p class="text-sm font-semibold text-gray-800 dark:text-gray-100">Series navigation</p>

              <div class="mt-3 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <div :if={@series_prev} class="flex items-center gap-2">
                  <span class="text-xs uppercase tracking-wide text-gray-500 dark:text-gray-400">
                    Previous
                  </span>

                  <.link
                    navigate={~p"/posts/#{@series_prev.slug}"}
                    class="text-sm font-semibold text-indigo-600 hover:text-indigo-500 dark:text-indigo-300"
                  >
                    <%= @series_prev.title %>
                  </.link>
                </div>

                <div :if={@series_next} class="flex items-center gap-2 sm:ml-auto">
                  <span class="text-xs uppercase tracking-wide text-gray-500 dark:text-gray-400">
                    Next
                  </span>

                  <.link
                    navigate={~p"/posts/#{@series_next.slug}"}
                    class="text-sm font-semibold text-indigo-600 hover:text-indigo-500 dark:text-indigo-300"
                  >
                    <%= @series_next.title %>
                  </.link>
                </div>
              </div>
            </section>

            <section
              :if={@related != []}
              class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-gray-900"
            >
              <p class="text-sm font-semibold text-gray-800 dark:text-gray-100">Related posts</p>

              <div class="mt-3 grid gap-3 md:grid-cols-2">
                <%= for rel <- @related do %>
                  <.link navigate={~p"/posts/#{rel.slug}"}>
                    <div class="rounded-xl border border-gray-200 bg-white p-3 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md dark:border-gray-800 dark:bg-gray-950">
                      <p class="text-xs text-gray-500 dark:text-gray-400">
                        <%= format_date(rel.inserted_at) %>
                      </p>

                      <h3 class="mt-1 text-base font-semibold text-gray-900 dark:text-gray-100">
                        <%= rel.title %>
                      </h3>

                      <p class="mt-1 text-sm text-gray-600 line-clamp-2 dark:text-gray-300">
                        <%= excerpt(rel.content) %>
                      </p>

                      <div class="mt-2 flex flex-wrap gap-1">
                        <span
                          :for={tag <- Markdown.tag_list(rel.tags)}
                          class="rounded-full bg-indigo-50 px-2 py-0.5 text-[11px] font-semibold text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-100"
                        >
                          <%= tag %>
                        </span>
                      </div>
                    </div>
                  </.link>
                <% end %>
              </div>
            </section>
          </div>

          <aside class="hidden space-y-4 md:block lg:sticky lg:top-10">
            <.live_component
              module={BlogWeb.TimelinePanel}
              id="timeline-panel"
              current_note_id={@note.id}
            />
            <div
              :if={@toc != []}
              class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-gray-900"
            >
              <p class="text-sm font-semibold text-gray-800 dark:text-gray-100">Table of contents</p>

              <nav class="mt-3 space-y-1">
                <%= for item <- @toc do %>
                  <a
                    href={"##{item.id}"}
                    class={[
                      "block rounded-md px-2 py-1 text-sm transition hover:bg-indigo-50 hover:text-indigo-700 dark:hover:bg-indigo-900/30",
                      item.level == 3 && "pl-5 text-gray-600 dark:text-gray-300"
                    ]}
                  >
                    <%= item.title %>
                  </a>
                <% end %>
              </nav>
            </div>
          </aside>
        </div>
      <% else %>
        <div class="rounded-xl border border-dashed border-gray-300 bg-gray-50 p-6 text-center text-sm text-gray-600 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300">
          해당 글을 찾을 수 없습니다.
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case NoteData.get_published_note_by_slug(slug) do
      nil ->
        {:ok,
         assign(socket,
           note: nil,
           title: "Not found",
           content_html: Phoenix.HTML.raw(""),
           toc: [],
           tags: [],
           reading_time: 0,
           published_on: "",
           image_path: nil,
           related: [],
           series_prev: nil,
           series_next: nil,
           page_title: "Not found",
           meta: %{title: "Not found"}
         )}

      note ->
        {content_html, toc} = content_and_toc(note)
        tags = Markdown.tag_list(note.tags)

        reading_time =
          note.reading_time || Markdown.reading_time_minutes(note.content || note.raw_markdown)

        related = NoteData.related_notes(note, 5)
        %{prev: series_prev, next: series_next} = NoteData.series_neighbors(note)

        seo = SEO.seo_assigns(:post, note)

        {:ok,
         socket
         |> assign(seo)
         |> assign(
           note: note,
           title: note.title,
           image_path: note.image_path,
           content_html: content_html,
           toc: toc,
           tags: tags,
           reading_time: reading_time,
           published_on: format_date(note.published_at || note.inserted_at),
           related: related,
           series_prev: series_prev,
           series_next: series_next
         )}
    end
  end

  defp format_date(%DateTime{} = date), do: Calendar.strftime(date, "%Y-%m-%d")
  defp format_date(%NaiveDateTime{} = date), do: Calendar.strftime(date, "%Y-%m-%d")
  defp format_date(_), do: ""

  defp content_and_toc(note) do
    cond do
      note.rendered_html && note.toc ->
        {Phoenix.HTML.raw(note.rendered_html), decode_toc(note.toc)}

      true ->
        Markdown.render_with_toc(note.raw_markdown || note.content)
    end
  end

  defp excerpt(content) do
    content
    |> to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.slice(0, 120)
    |> case do
      text when byte_size(text) < 120 -> text
      text -> text <> "…"
    end
  end

  defp decode_toc(toc_json) do
    with {:ok, list} <- Jason.decode(toc_json) do
      Enum.map(list, fn
        %{"id" => id, "title" => title, "level" => level} -> %{id: id, title: title, level: level}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
    else
      _ -> []
    end
  end
end
