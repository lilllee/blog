defmodule BlogWeb.NoteLive do
  use BlogWeb, :live_view
  alias BlogWeb.{DuckComponents}

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

  def mount(%{"id" => id}, _session, socket) do
    with {:ok, componet} <- DuckComponents.init_duck_db(%{table_nm: "note"}),
         {:ok, result} <- Duckdbex.query(componet.conn, Enum.join(["SELECT id, title, content, imagePath from note where id=", id])),
         post <- Duckdbex.fetch_all(result)
              |> Enum.map(fn [id, title, content, imagePath] ->
                %{id: id, title: title, content: content, imagePath: imagePath}
              end) do
         first_list = post |> List.first()
         {:ok, assign(socket, title: first_list.title, imagePath: first_list.imagePath, content: markdown([content: first_list.content]))}
    else
      {:error, reason} ->
        IO.inspect(reason, label: "ERROR")
        {:error, reason}
      other ->
        IO.inspect(other, label: "UNEXPECTED ERROR")
        {:error, other}
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
