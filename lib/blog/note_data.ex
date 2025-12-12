defmodule Blog.NoteData do
  import Ecto.Query
  alias Blog.Note
  alias Blog.Repo

  def get_all_notes() do
    from(note in Note,
      select: note,
      order_by: [desc: note.inserted_at]
    )
    |> Repo.all()
  end

  def get_note_by_id(id) do
    Repo.get(Note, id)
  end

  def search_notes(query_string) do
    search_pattern = "%#{query_string}%"

    from(note in Note,
      where: like(note.title, ^search_pattern) or like(note.content, ^search_pattern),
      order_by: [desc: note.inserted_at]
    )
    |> Repo.all()
  end
end
