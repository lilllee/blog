defmodule BlogWeb.NoteLive do
  use BlogWeb, :live_view

  alias Blog.NoteData
  alias Blog.Translation
  alias BlogWeb.Markdown
  alias BlogWeb.SEO

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @note do %>
      <.link navigate={~p"/"} class="back">← <%= Translation.t("back_to_list", @locale) %></.link>

      <article>
        <h1><%= @title %></h1>
        <p class="meta">
          <%= @published_on %>
          <%= if @reading_time > 0 do %>
            · <%= @reading_time %> <%= Translation.t("min_read", @locale) %>
          <% end %>
        </p>

        <%= @content_html %>
      </article>

      <footer class="qfooter">
        <.link navigate={~p"/"}>← <%= Translation.t("back_to_list", @locale) %></.link>
        <span class="langs">
          <button
            :for={code <- ~w(ko en ja zh)}
            type="button"
            phx-click="set_locale"
            phx-value-locale={code}
            class={if @locale == code, do: "current"}
          ><%= lang_label(code) %></button>
        </span>
      </footer>
    <% else %>
      <.link navigate={~p"/"} class="back">← <%= Translation.t("back_to_list", @locale) %></.link>
      <p style="color: var(--muted); margin-top: 24px;">
        <%= Translation.t("not_found", @locale) %>
      </p>
    <% end %>
    """
  end

  defp lang_label("ko"), do: "한국어"
  defp lang_label("en"), do: "English"
  defp lang_label("ja"), do: "日本語"
  defp lang_label("zh"), do: "中文"

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
           reading_time: 0,
           published_on: "",
           page_title: "Not found",
           meta: %{title: "Not found"},
           original_note: nil
         )}

      note ->
        content_html = render_content(note)

        reading_time =
          note.reading_time || Markdown.reading_time_minutes(note.content || note.raw_markdown)

        seo = SEO.seo_assigns(:post, note)

        socket =
          socket
          |> assign(seo)
          |> assign(
            note: note,
            original_note: note,
            title: note.title,
            content_html: content_html,
            reading_time: reading_time,
            published_on: format_date(note.published_at || note.inserted_at)
          )

        if locale != "ko" and connected?(socket) do
          send(self(), {:translate, locale})
        end

        {:ok, socket}
    end
  end

  @impl true
  def handle_info({:locale_changed, locale}, socket) do
    case socket.assigns[:original_note] do
      nil ->
        {:noreply, socket}

      note ->
        if locale == "ko" do
          {:noreply,
           assign(socket, title: note.title, content_html: render_content(note))}
        else
          send(self(), {:translate, locale})
          {:noreply, socket}
        end
    end
  end

  def handle_info({:translate, locale}, socket) do
    note = socket.assigns[:original_note]

    if note do
      pid = self()

      Task.start(fn ->
        translated = Translation.translate_post(note, locale)
        send(pid, {:translation_complete, translated, locale})
      end)
    end

    {:noreply, socket}
  end

  def handle_info({:translation_complete, translated, locale}, socket) do
    if socket.assigns[:locale] == locale do
      {:noreply,
       assign(socket,
         title: translated.title,
         content_html: render_content(translated)
       )}
    else
      {:noreply, socket}
    end
  end

  defp render_content(note) do
    cond do
      note.rendered_html && note.rendered_html != "" ->
        Phoenix.HTML.raw(note.rendered_html)

      true ->
        Markdown.render(note.raw_markdown || note.content || "")
    end
  end

  defp format_date(%DateTime{} = d), do: Calendar.strftime(d, "%Y.%m.%d")
  defp format_date(%NaiveDateTime{} = d), do: Calendar.strftime(d, "%Y.%m.%d")
  defp format_date(_), do: ""
end
