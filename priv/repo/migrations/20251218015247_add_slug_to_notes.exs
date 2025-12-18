defmodule Blog.Repo.Migrations.AddSlugToNotes do
  use Ecto.Migration

  def up do
    alter table(:note) do
      add :slug, :string
    end

    # Backfill slugs from existing titles
    execute """
    UPDATE note
    SET slug = LOWER(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    TRIM(title),
                    ' ', '-'
                  ),
                  '&', 'and'
                ),
                '!', ''
              ),
              '?', ''
            ),
              ':', ''
            ),
            '.', ''
          ),
          ',', ''
        )
      )
    WHERE slug IS NULL;
    """

    # Add unique constraint after backfilling
    create unique_index(:note, [:slug])
  end

  def down do
    drop index(:note, [:slug])

    alter table(:note) do
      remove :slug
    end
  end
end
