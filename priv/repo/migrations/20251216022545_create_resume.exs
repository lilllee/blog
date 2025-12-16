defmodule Blog.Repo.Migrations.CreateResume do
  use Ecto.Migration

  def change do
    create table(:resume) do
      add :header, :text
      add :skills, :text
      add :experience, :text
      add :projects, :text
      add :education, :text
      add :additional, :text

      timestamps(type: :utc_datetime)
    end

    # Seed with empty record
    execute(
      """
      INSERT INTO resume (header, skills, experience, projects, education, additional, inserted_at, updated_at)
      VALUES (
        '{"name":"","title":"","email":"","phone":"","location":"","linkedin":"","github":"","website":""}',
        '[]',
        '[]',
        '[]',
        '[]',
        '{"summary_md":"","certifications":[],"languages":[],"interests":[]}',
        datetime('now'),
        datetime('now')
      )
      """,
      "DELETE FROM resume"
    )
  end
end
