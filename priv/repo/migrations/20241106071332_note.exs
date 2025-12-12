defmodule Blog.Repo.Migrations.Note do
  use Ecto.Migration

  def change do
    create table(:note) do
      add :title, :string, null: false
      add :content, :text, null: false
      add :image_path, :string
      add :tags, :string
      add :categories, :string
      add :inserted_at, :utc_datetime
      add :updated_at, :utc_datetime
    end

    create index(:note, [:title])
    create index(:note, [:tags])
  end
end
