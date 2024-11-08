defmodule BlogWeb.FormComponent do
  use BlogWeb, :live_component
  alias Earmark

  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col justify-center items-center dark:text-white descendant:dark:text-white">
      <article class={["prose dark:prose-invert prose-a:text-blue-600 descendant:dark:text-white",]}>
        <%= Earmark.as_html!(@input, escape: false, inner_html: true, compact_output: true)
        |> HtmlSanitizeEx.basic_html()
        |> Phoenix.HTML.raw() %>
      </article>
    </div>
    """
  end

  def mount(socket) do
    socket =
      socket
      |> allow_upload(:markdown, accept: ~w(.md), max_entries: 1, max_file_size: 5 * 1024 * 1024)
    {:ok, assign(socket, markdown_html: "")}
  end

  def handle_event("save", %{"markdown" => _}, socket) do
    uploaded_file =
      consume_uploaded_entries(socket, :markdown, fn %{path: path}, _entry ->
        # Read the markdown file from the temporary upload path
        File.read!(path)
      end)
      |> List.first()

    markdown_html =
      case uploaded_file do
        nil -> ""
        content -> Earmark.as_html!(content)
      end

    {:noreply, assign(socket, :markdown_html, markdown_html)}
  end
end
