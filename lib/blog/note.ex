defmodule Blog.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "note" do
    field :title, :string
    field :content, :string
    field :raw_markdown, :string
    field :rendered_html, :string
    field :reading_time, :integer
    field :toc, :string
    field :status, :string, default: "published"
    field :published_at, :utc_datetime
    field :deleted_at, :utc_datetime
    field :image_path, :string
    field :tags, :string
    field :categories, :string
    field :series_id, :string
    field :series_order, :integer

    timestamps(type: :utc_datetime)
  end

  def changeset(note, params \\ %{}) do
    note
    |> cast(params, [
      :title,
      :content,
      :raw_markdown,
      :rendered_html,
      :reading_time,
      :toc,
      :status,
      :published_at,
      :deleted_at,
      :image_path,
      :tags,
      :categories,
      :series_id,
      :series_order
    ])
    |> validate_required([:title, :content])
    |> validate_inclusion(:status, ["draft", "published"])
  end
end
