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
        class="fixed top-16 right-6 z-50 flex items-center gap-2 border border-border bg-[var(--tm-chrome)] px-3 py-2"
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

      <%= if @note do %>
        <%!-- ← cd .. --%>
        <.link
          navigate={~p"/"}
          class="tm-link inline-block pt-5 pb-2 text-[13px] text-muted-foreground"
        >
          ← cd ..
        </.link>

        <%!-- $ cat slug.md --%>
        <div class="flex flex-wrap items-center gap-2.5 pt-2 pb-3 text-sm">
          <span class="text-tm-accent">junho</span>
          <span class="text-tm-blue">~/blog/posts</span>
          <span class="text-muted-foreground">$</span>
          <span class="text-foreground">cat <%= @note.slug %>.md</span>
        </div>

        <hr class="my-5 border-0 border-t border-dashed border-border" />

        <article>
          <%!-- Date · tag · reading time --%>
          <div class="py-3 text-xs text-muted-foreground">
            <%= @published_on %>
            <%= if @tags != [] do %>
              <span> · </span>
              <span class="text-tm-blue"><%= @tags |> List.first() |> String.downcase() %></span>
            <% end %>
            <%= if @reading_time > 0 do %>
              <span> · </span>
              <span><%= @reading_time %> min read</span>
            <% end %>
          </div>

          <%!-- # title --%>
          <h1 class="mt-3 text-[26px] leading-tight font-bold tracking-tight text-foreground text-balance">
            <span class="text-tm-accent">#</span> <%= @title %>
          </h1>

          <%!-- Cover image --%>
          <div :if={@image_path} class="mt-6 border border-border">
            <img
              phx-track-static
              src={"/images/" <> @image_path}
              alt={@title}
              width="672"
              height="378"
              loading="eager"
              fetchpriority="high"
              decoding="async"
              class="block w-full"
            />
          </div>

          <%!-- TOC --%>
          <%= if is_list(@toc) and @toc != [] do %>
            <div class="mt-6 border border-dashed border-border bg-[var(--tm-chrome)] p-4">
              <div class="text-[11px] uppercase tracking-[0.1em] text-muted-foreground">
                table of contents
              </div>
              <div class="mt-2">
                <a
                  :for={t <- @toc}
                  href={"#" <> t.id}
                  class="tm-link block py-1 text-[13px] text-muted-foreground"
                  style={"padding-left: #{(t.level - 2) * 16}px"}
                >
                  <%= if t.level == 2, do: "▸ ", else: "· " %><%= t.title %>
                </a>
              </div>
            </div>
          <% end %>

          <%!-- Article body --%>
          <div class="pt-8 pb-8 prose-blog">
            <%= @content_html %>
          </div>

          <%!-- $ echo "end of file" --%>
          <div class="mt-2 pt-6 border-t border-dashed border-border text-xs text-muted-foreground">
            <div>$ echo "end of file"</div>
            <div class="mt-1 text-foreground">end of file</div>
          </div>

          <%!-- Series navigation --%>
          <section
            :if={@series_prev || @series_next}
            class="mt-10 border border-dashed border-border p-4"
          >
            <p class="text-[11px] uppercase tracking-[0.1em] text-muted-foreground">
              $ <%= Translation.t("series_nav", @locale) %>
            </p>
            <div class="mt-3 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div :if={@series_prev} class="flex flex-col gap-1">
                <span class="text-[11px] text-muted-foreground">
                  ← <%= Translation.t("prev", @locale) %>
                </span>
                <.link
                  navigate={~p"/posts/#{@series_prev.slug}"}
                  class="tm-link text-sm text-foreground"
                >
                  <%= @series_prev.title %>
                </.link>
              </div>
              <div :if={@series_next} class="flex flex-col gap-1 sm:ml-auto sm:text-right">
                <span class="text-[11px] text-muted-foreground">
                  <%= Translation.t("next", @locale) %> →
                </span>
                <.link
                  navigate={~p"/posts/#{@series_next.slug}"}
                  class="tm-link text-sm text-foreground"
                >
                  <%= @series_next.title %>
                </.link>
              </div>
            </div>
          </section>

          <%!-- Chronological navigation --%>
          <nav :if={@chrono_prev || @chrono_next} class="mt-6 grid grid-cols-2 gap-3">
            <div>
              <.link
                :if={@chrono_prev}
                navigate={~p"/posts/#{@chrono_prev.slug}"}
                class="tm-row group block border border-dashed border-border p-3"
              >
                <span class="text-[11px] text-muted-foreground">
                  ← <%= Translation.t("prev", @locale) %>
                </span>
                <p class="mt-1 text-sm text-foreground line-clamp-2">
                  <%= @chrono_prev.title %>
                </p>
              </.link>
            </div>
            <div class="text-right">
              <.link
                :if={@chrono_next}
                navigate={~p"/posts/#{@chrono_next.slug}"}
                class="tm-row group block border border-dashed border-border p-3"
              >
                <span class="text-[11px] text-muted-foreground">
                  <%= Translation.t("next", @locale) %> →
                </span>
                <p class="mt-1 text-sm text-foreground line-clamp-2">
                  <%= @chrono_next.title %>
                </p>
              </.link>
            </div>
          </nav>

          <%!-- Related posts --%>
          <section :if={@related != []} class="mt-10 pt-6 border-t border-dashed border-border">
            <p class="text-[11px] uppercase tracking-[0.1em] text-muted-foreground">
              $ ls related/
            </p>
            <div class="mt-3">
              <.link
                :for={rel <- @related}
                navigate={~p"/posts/#{rel.slug}"}
                class="tm-row block py-3 border-b border-dashed border-border last:border-b-0"
              >
                <div class="flex items-center gap-2 text-[11px] text-muted-foreground">
                  <time><%= format_date(rel.inserted_at) %></time>
                </div>
                <h3 class="mt-1 text-sm text-foreground">
                  <span class="text-tm-accent">▸</span> <%= rel.title %>
                </h3>
              </.link>
            </div>
          </section>
        </article>
      <% else %>
        <.link
          navigate={~p"/"}
          class="tm-link inline-block pt-5 pb-2 text-[13px] text-muted-foreground"
        >
          ← cd ..
        </.link>
        <div class="mt-8 py-16 text-center text-muted-foreground text-sm">
          $ cat: <%= Translation.t("not_found", @locale) %>
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
