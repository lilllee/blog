defmodule Blog.Slug do
  @moduledoc """
  Generates URL-friendly slugs from text.
  """

  @doc """
  Generates a slug from a string.

  ## Examples
      iex> Blog.Slug.generate("Hello World!")
      "hello-world"

      iex> Blog.Slug.generate("Elixir & Phoenix: 123 Tips")
      "elixir-phoenix-123-tips"
  """
  def generate(nil), do: ""

  def generate(text) when is_binary(text) do
    text
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
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
