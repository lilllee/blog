defmodule Blog.Repo.Migrations.CreateTranslations do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :content_hash, :string, null: false
      add :source_lang, :string, null: false, default: "ko"
      add :target_lang, :string, null: false
      add :original_text, :text, null: false
      add :translated_text, :text, null: false

      timestamps()
    end

    create unique_index(:translations, [:content_hash, :target_lang])
    create index(:translations, [:source_lang])
    create index(:translations, [:target_lang])
  end
end
