# defmodule Blog.NoteData do

#   import Ecto.Query
#   alias Blog.NoteData
#   alias Blog.Note
#   alias Blog.Repo

#   def get_all_content() do
#     from( note in Blog.Note,
#       select: [ note.title, note.content, note.inserted_at, note.id ],
#       order_by: note.inserted_at
#     )
#     |> Repo.all()
#     |> Enum.map(fn [title, content, inserted_at, id] ->
#       %{title: title, content: content, inserted_at: inserted_at, id: id}
#     end)
#   end

#   def get_content_by_id( opts ) do
#     id = Keyword.get(opts, :id, 0)
#     from( note in Blog.Note,
#       where: note.id == ^id,
#       select: %{ content: note.content, title: note.title }
#     )
#     |> Repo.one()
#   end

#   def get_content_by_title( opts ) do
#     title = Keyword.get(opts, :title, "")
#     {:ok, result} = Repo.query("Select title, content, inserted_at, id from note where title like '%#{title}%'")

#     result.rows
#     |> Enum.map(fn [title, content, inserted_at, id] ->
#       %{title: title, content: content, inserted_at: inserted_at, id: id}
#     end)
#   end
# end
