defmodule BlogWeb.NoteLive do
  use BlogWeb, :live_view
  alias Blog.NoteData

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.header>
    </.header>
    <article class="markdown-body">
      <h1><%= @title %></h1>
      <img phx-track-static src={~p"/images/#{@imagePath}"} alt="Note Image"
      class="w-full h-60 object-cover hover:rotate-1 hover:scale- transition-transform duration-300" />
      <%= @content %>
    </article>
    """
  end

  @spec mount(any(), any(), any()) :: none()
  def mount(%{"id" => id}, _session, socket) do
    case NoteData.get_note_by_id(id) do
      nil ->
        {:ok, assign(socket, error: "Note not found")}

      note ->
        {:ok, assign(socket,
          title: note.title,
          imagePath: note.image_path,
          content: markdown([content: note.content])
        )}
    end
  end

  @spec markdown(keyword()) ::
          {:safe,
           binary()
           | maybe_improper_list(
               binary() | maybe_improper_list(any(), binary() | []) | byte(),
               binary() | []
             )}
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
