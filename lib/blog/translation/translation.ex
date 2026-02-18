defmodule Blog.Translation.Translation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Blog.Repo

  @supported_languages ~w(ko en ja zh)

  schema "translations" do
    field :content_hash, :string
    field :source_lang, :string, default: "ko"
    field :target_lang, :string
    field :original_text, :string
    field :translated_text, :string

    timestamps()
  end

  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:content_hash, :source_lang, :target_lang, :original_text, :translated_text])
    |> validate_required([:content_hash, :source_lang, :target_lang, :original_text, :translated_text])
    |> validate_inclusion(:source_lang, @supported_languages)
    |> validate_inclusion(:target_lang, @supported_languages)
    |> unique_constraint([:content_hash, :target_lang])
  end

  def supported_languages, do: @supported_languages

  def language_names do
    %{
      "ko" => "한국어",
      "en" => "English",
      "ja" => "日本語",
      "zh" => "中文"
    }
  end

  def get_cached(content_hash, target_lang) do
    from(t in __MODULE__,
      where: t.content_hash == ^content_hash and t.target_lang == ^target_lang
    )
    |> Repo.one()
  end

  def cache_translation(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  def compute_hash(text) do
    :crypto.hash(:sha256, text)
    |> Base.encode16(case: :lower)
  end
end
