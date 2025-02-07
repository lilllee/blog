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
    db = Duckdbex.open() |> elem(1)
    conn = Duckdbex.connection(db) |> elem(1)
    post = case Duckdbex.query( conn, """
        CREATE TABLE note AS
        SELECT * FROM read_csv_auto(
          'note.csv',
          delim='|',
          quote='"',
          escape='"',
          header=true,
          ignore_errors=true,
          null_padding=true,
          all_varchar=true
        )
    """) do
      {:ok, _result} ->
        case Duckdbex.query(conn, Enum.join(["SELECT id, title, content, imagePath from note where id=", id])) do
           {:ok, query_result} ->
            query_result
            |> Duckdbex.fetch_all()
            |> Enum.map(fn [id, title, content, imagePath] ->
              %{id: id, title: title, content: content, imagePath: imagePath}
            end)
            {:error, err} ->
              IO.inspect(err, label: "SELECT ERROR")
              []
        end
        {:error, err} -> IO.inspect(err, label: "CREATE TABLE ERROR")
    end |> List.first()

    {:ok, assign(socket, title: post.title, imagePath: post.imagePath, content: markdown([content: post.content]))}
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
