defmodule Blog.Music.MusicTrack do
  use Ecto.Schema
  import Ecto.Changeset

  schema "music_tracks" do
    field :title, :string
    field :file_path, :string
    field :mime_type, :string
    field :file_size, :integer
    field :duration_sec, :integer

    timestamps()
  end

  def changeset(track, attrs) do
    track
    |> cast(attrs, [:title, :file_path, :mime_type, :file_size, :duration_sec])
    |> validate_required([:title, :file_path, :mime_type, :file_size])
    |> validate_number(:file_size, greater_than: 0)
    |> unique_constraint(:file_path)
  end
end
