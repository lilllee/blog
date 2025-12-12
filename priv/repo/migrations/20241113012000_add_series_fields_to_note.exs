defmodule Blog.Repo.Migrations.AddSeriesFieldsToNote do
  use Ecto.Migration

  def change do
    alter table(:note) do
      add :series_id, :string
      add :series_order, :integer
    end

    create index(:note, [:series_id])
  end
end
