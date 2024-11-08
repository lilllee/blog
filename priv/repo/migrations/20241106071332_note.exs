defmodule Blog.Repo.Migrations.Note do
  use Ecto.Migration

  def change do
    create table(:note) do
      add :title, :string
      add :content, :text

      timestamps()
    end
  end
end
