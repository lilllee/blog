# defmodule Blog.Note do
#   use Ecto.Schema
#   import Ecto.Changeset

#   schema "note" do
#     field :title, :string
#     field :content, :string
#     field :inserted_at, :utc_datetime
#     field :updated_at, :utc_datetime
#   end

#   # 유효성 검사 추가.
#   def changeset(note, params \\ %{}) do
#     note
#     |> cast(params, [:title, :content])
#     |> validate_required([:title, :content])
#   end
# end
