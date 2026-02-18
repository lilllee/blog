defmodule BlogWeb.NoteLive do
  use BlogWeb, :live_view

  alias Blog.NoteData
  alias Blog.Translation
  alias BlogWeb.Markdown
  alias BlogWeb.SEO

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Translation loading indicator --%>
      <div
        :if={@translating}
        class="fixed top-16 right-6 z-50 flex items-center gap-2 rounded-lg bg-background border border-border px-3 py-2 shadow-lg"
      >
        <svg
          class="h-4 w-4 animate-spin text-muted-foreground"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
          </circle>
          <path
            class="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          >
          </path>
        </svg>
        <span class="text-xs text-muted-foreground">Translating...</span>
      </div>

      <%!-- Back link --%>
      <.link
        navigate={~p"/"}
        class="inline-flex items-center gap-1.5 text-sm text-muted-foreground transition-colors hover:text-foreground"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          class="h-4 w-4"
        >
          <path
            fill-rule="evenodd"
            d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z"
            clip-rule="evenodd"
          />
        </svg>
        <%= Translation.t("back_to_list", @locale) %>
      </.link>

      <%= if @note do %>
        <article class="mt-10">
          <%!-- Article header --%>
          <header class="pb-10 border-b border-border/50">
            <div class="flex items-center gap-2.5 flex-wrap">
              <time class="text-xs font-medium tracking-wide text-muted-foreground/70">
                <%= @published_on %>
              </time>
              <%= for tag <- @tags do %>
                <span class="text-muted-foreground/30">/</span>
                <span class="rounded-full bg-secondary px-2.5 py-0.5 text-xs font-medium text-muted-foreground">
                  <%= tag %>
                </span>
              <% end %>
              <span :if={@reading_time > 0} class="text-muted-foreground/30">&middot;</span>
              <span :if={@reading_time > 0} class="text-xs font-medium text-muted-foreground">
                <%= @reading_time %> min read
              </span>
            </div>
            <h1 class="mt-4 text-3xl font-bold tracking-tight text-foreground leading-tight text-balance">
              <%= @title %>
            </h1>
          </header>

          <%!-- Cover image --%>
          <div :if={@image_path} class="mt-10 overflow-hidden rounded-lg">
            <img
              phx-track-static
              src={"/images/" <> @image_path}
              alt={@title}
              width="672"
              height="378"
              loading="eager"
              fetchpriority="high"
              decoding="async"
              class="w-full object-cover"
            />
          </div>

          <%!-- Article body --%>
          <div class="pt-10 prose-blog text-base text-foreground/85">
            <%= @content_html %>
          </div>

          <%!-- Series navigation --%>
          <section
            :if={@series_prev || @series_next}
            class="mt-10 rounded-lg border border-border/50 p-5"
          >
            <p class="text-xs font-semibold uppercase tracking-wide text-muted-foreground/60">
              <%= Translation.t("series_nav", @locale) %>
            </p>
            <div class="mt-3 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div :if={@series_prev} class="flex flex-col gap-1">
                <span class="text-xs text-muted-foreground/50">
                  <%= Translation.t("prev", @locale) %>
                </span>
                <.link
                  navigate={~p"/posts/#{@series_prev.slug}"}
                  class="text-sm font-medium text-foreground hover:text-muted-foreground transition-colors"
                >
                  <%= @series_prev.title %>
                </.link>
              </div>
              <div :if={@series_next} class="flex flex-col gap-1 sm:ml-auto sm:text-right">
                <span class="text-xs text-muted-foreground/50">
                  <%= Translation.t("next", @locale) %>
                </span>
                <.link
                  navigate={~p"/posts/#{@series_next.slug}"}
                  class="text-sm font-medium text-foreground hover:text-muted-foreground transition-colors"
                >
                  <%= @series_next.title %>
                </.link>
              </div>
            </div>
          </section>

          <%!-- Chronological navigation --%>
          <nav :if={@chrono_prev || @chrono_next} class="mt-10 grid grid-cols-2 gap-4">
            <div>
              <.link
                :if={@chrono_prev}
                navigate={~p"/posts/#{@chrono_prev.slug}"}
                class="group block rounded-lg border border-border/50 p-4 transition-colors hover:bg-muted"
              >
                <span class="text-xs text-muted-foreground">
                  <%= Translation.t("prev", @locale) %>
                </span>
                <p class="mt-1 text-sm font-medium text-foreground group-hover:text-foreground/80 transition-colors line-clamp-2">
                  <%= @chrono_prev.title %>
                </p>
              </.link>
            </div>
            <div class="text-right">
              <.link
                :if={@chrono_next}
                navigate={~p"/posts/#{@chrono_next.slug}"}
                class="group block rounded-lg border border-border/50 p-4 transition-colors hover:bg-muted"
              >
                <span class="text-xs text-muted-foreground">
                  <%= Translation.t("next", @locale) %>
                </span>
                <p class="mt-1 text-sm font-medium text-foreground group-hover:text-foreground/80 transition-colors line-clamp-2">
                  <%= @chrono_next.title %>
                </p>
              </.link>
            </div>
          </nav>

          <%!-- Related posts --%>
          <section :if={@related != []} class="mt-10 pt-10 border-t border-border/50">
            <p class="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground/60">
              <%= Translation.t("related_posts", @locale) %>
            </p>
            <div class="mt-6 divide-y divide-border/50">
              <%= for rel <- @related do %>
                <.link navigate={~p"/posts/#{rel.slug}"} class="group block py-4 first:pt-0">
                  <div class="flex items-center gap-2.5">
                    <time class="text-xs font-medium tracking-wide text-muted-foreground/70">
                      <%= format_date(rel.inserted_at) %>
                    </time>
                  </div>
                  <h3 class="mt-1.5 text-base font-semibold text-foreground group-hover:text-muted-foreground transition-colors">
                    <%= rel.title %>
                  </h3>
                  <p class="mt-1 text-sm text-muted-foreground line-clamp-2">
                    <%= excerpt(rel.content) %>
                  </p>
                </.link>
              <% end %>
            </div>
          </section>
        </article>
      <% else %>
        <div class="mt-10 py-16 text-center">
          <p class="text-sm text-muted-foreground"><%= Translation.t("not_found", @locale) %></p>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    locale = socket.assigns[:locale] || "ko"

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
           chrono_prev: nil,
           chrono_next: nil,
           page_title: "Not found",
           meta: %{title: "Not found"},
           translating: false,
           original_note: nil
         )}

      note ->
        {content_html, toc} = content_and_toc(note)
        tags = Markdown.tag_list(note.tags)

        reading_time =
          note.reading_time || Markdown.reading_time_minutes(note.content || note.raw_markdown)

        related = NoteData.related_notes(note, 5)
        %{prev: series_prev, next: series_next} = NoteData.series_neighbors(note)
        %{prev: chrono_prev, next: chrono_next} = NoteData.chronological_neighbors(note)

        seo = SEO.seo_assigns(:post, note)

        # Add breadcrumb JSON-LD alongside BlogPosting
        base_url = BlogWeb.Endpoint.url()

        breadcrumb =
          SEO.breadcrumb_schema([
            {"Home", base_url},
            {"Posts", base_url <> "/"},
            {note.title, base_url <> "/posts/#{note.slug}"}
          ])

        combined_json_ld =
          [
            SEO.blog_posting_schema(note, base_url <> "/posts/#{note.slug}"),
            breadcrumb
          ]
          |> SEO.encode_schema()

        seo = Map.put(seo, :json_ld, combined_json_ld)

        socket =
          socket
          |> assign(seo)
          |> assign(
            note: note,
            original_note: note,
            title: note.title,
            image_path: note.image_path,
            content_html: content_html,
            toc: toc,
            tags: tags,
            reading_time: reading_time,
            published_on: format_date(note.published_at || note.inserted_at),
            related: related,
            series_prev: series_prev,
            series_next: series_next,
            chrono_prev: chrono_prev,
            chrono_next: chrono_next,
            translating: false
          )

        if locale != "ko" and connected?(socket) do
          send(self(), {:translate, locale})
        end

        {:ok, socket}
    end
  end

  @impl true
  def handle_info({:locale_changed, locale}, socket) do
    if socket.assigns[:original_note] do
      if locale == "ko" do
        note = socket.assigns.original_note
        {content_html, toc} = content_and_toc(note)

        {:noreply,
         assign(socket,
           title: note.title,
           content_html: content_html,
           toc: toc,
           translating: false
         )}
      else
        send(self(), {:translate, locale})
        {:noreply, assign(socket, translating: true)}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:translate, locale}, socket) do
    note = socket.assigns[:original_note]

    if note do
      Task.start(fn ->
        translated = Translation.translate_post(note, locale)
        send(socket.root_pid, {:translation_complete, translated, locale})
      end)

      {:noreply, assign(socket, translating: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:translation_complete, translated_note, locale}, socket) do
    if socket.assigns[:locale] == locale do
      {content_html, toc} = content_and_toc(translated_note)

      {:noreply,
       assign(socket,
         title: translated_note.title,
         content_html: content_html,
         toc: toc,
         translating: false
       )}
    else
      {:noreply, socket}
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
