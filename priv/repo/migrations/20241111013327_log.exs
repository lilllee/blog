defmodule Blog.Repo.Migrations.Log do
  use Ecto.Migration

  def change do
    create table(:log) do
      add :location, :string
      add :event, :string
      add :ip, :string
      add :input, :string

      timestamps()
    end
  end
end
