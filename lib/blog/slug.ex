defmodule Blog.Slug do
  @moduledoc """
  Generates URL-friendly slugs from text.
  Supports Korean (Hangul), Japanese (Kana/Kanji), Chinese (CJK), and Latin characters.
  """

  @doc """
  Generates a slug from a string.

  ## Examples
      iex> Blog.Slug.generate("Hello World!")
      "hello-world"

      iex> Blog.Slug.generate("Elixir & Phoenix: 123 Tips")
      "elixir-phoenix-123-tips"

      iex> Blog.Slug.generate("한글 제목 테스트")
      "한글-제목-테스트"
  """
  def generate(nil), do: ""

  def generate(text) when is_binary(text) do
    slug =
      text
      |> String.downcase()
      |> String.replace(~r/[^\p{L}\p{N}\s-]/u, "")
      |> String.replace(~r/\s+/, "-")
      |> String.replace(~r/-+/, "-")
      |> String.trim("-")

    if slug == "" do
      "post-#{System.os_time(:second)}"
    else
      slug
    end
  end

  @doc """
  Ensures slug uniqueness by appending a counter if needed.
  """
  def ensure_unique(slug, existing_slugs) when is_list(existing_slugs) do
    if slug in existing_slugs do
      append_counter(slug, existing_slugs, 2)
    else
      slug
    end
  end

  defp append_counter(base_slug, existing_slugs, counter) do
    candidate = "#{base_slug}-#{counter}"

    if candidate in existing_slugs do
      append_counter(base_slug, existing_slugs, counter + 1)
    else
      candidate
    end
  end
end
