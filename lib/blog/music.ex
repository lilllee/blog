defmodule Blog.Music do
  import Ecto.Query

  alias Blog.Music.MusicTrack
  alias Blog.Repo

  def list_tracks do
    MusicTrack
    |> order_by([t], asc: t.inserted_at)
    |> Repo.all()
  end

  def get_track!(id), do: Repo.get!(MusicTrack, id)

  def change_track(%MusicTrack{} = track, attrs \\ %{}) do
    MusicTrack.changeset(track, attrs)
  end

  def create_track(attrs) do
    %MusicTrack{}
    |> MusicTrack.changeset(attrs)
    |> Repo.insert()
  end
end
