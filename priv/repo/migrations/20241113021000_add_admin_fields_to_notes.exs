defmodule Blog.Repo.Migrations.AddAdminFieldsToNotes do
  use Ecto.Migration

  def change do
    alter table(:note) do
      add :raw_markdown, :text
      add :rendered_html, :text
      add :reading_time, :integer
      add :toc, :text
      add :status, :string, default: "published", null: false
      add :published_at, :utc_datetime
      add :deleted_at, :utc_datetime
    end

    create index(:note, [:status])
    create index(:note, [:deleted_at])

    execute(
      "UPDATE note SET raw_markdown = content, status = 'published', published_at = COALESCE(published_at, inserted_at)"
    )
  end
end
