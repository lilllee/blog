defmodule Blog.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "note" do
    field :title, :string
    field :content, :string
    field :image_path, :string
    field :tags, :string
    field :categories, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(note, params \\ %{}) do
    note
    |> cast(params, [:title, :content, :image_path, :tags, :categories])
    |> validate_required([:title, :content])
  end
end
