defmodule Blog.Repo.Migrations.CreateMusicTracks do
  use Ecto.Migration

  def change do
    create table(:music_tracks) do
      add :title, :string, null: false
      add :file_path, :string, null: false
      add :mime_type, :string, null: false
      add :file_size, :integer, null: false
      add :duration_sec, :integer

      timestamps()
    end

    create unique_index(:music_tracks, [:file_path])
  end
end
