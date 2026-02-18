defmodule BlogWeb.RedirectController do
  use BlogWeb, :controller

  alias Blog.NoteData

  def posts_index(conn, _params) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: ~p"/")
  end

  @doc """
  Handles 301 redirect from old /item/:id URLs to new /posts/:slug URLs.
  Preserves SEO and prevents 404s for indexed URLs.
  """
  def old_item_to_slug(conn, %{"id" => id}) do
    case NoteData.get_published_note(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(html: BlogWeb.ErrorHTML)
        |> render(:"404")

      note ->
        conn
        |> put_status(:moved_permanently)
        |> redirect(to: ~p"/posts/#{note.slug}")
    end
  end
end
