defmodule BlogWeb.NoteLive do
  use BlogWeb, :live_view

  alias Blog.NoteData

  def render(assigns) do
    ~H"""
    <.header>
    </.header>
    <article class="markdown-body">
      <h1><%= @title %></h1>
      <%= @content %>
    </article>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    note = NoteData.get_content_by_id([id: id])
    {:ok, assign(socket, title: note.title, content: markdown([content: note.content]))}
  end

  def markdown(content) do
    content = Keyword.get(content, :content, "")
    MDEx.to_html!(content,
      extension: [
        strikethrough: true,
        tagfilter: true,
        table: true,
        autolink: true,
        tasklist: true,
        footnotes: true,
        shortcodes: true,
      ],
      parse: [
        smart: true,
        relaxed_tasklist_matching: true,
        relaxed_autolinks: true
      ],
      render: [
        github_pre_lang: true,
        unsafe_: true,
        escape: true,
      ],
      features: [
        sanitize: true,
      ]
    )
    |> Phoenix.HTML.raw()
  end
end