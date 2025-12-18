defmodule BlogWeb.OGImage do
  @moduledoc """
  Open Graph image helper for social sharing optimization.
  Handles both static and dynamic OG image generation.
  """

  @default_image "/images/og-default.png"
  @post_images_path "/images/posts/"

  @doc """
  Returns the best OG image URL for the given content.
  Tries in order: custom image → post image → category image → default.
  """
  def get_image_url(type, data \\ %{})

  def get_image_url(:post, note) when is_map(note) do
    base_url = BlogWeb.Endpoint.url()

    cond do
      # 1. Post has custom OG image
      note.image_path && String.starts_with?(note.image_path, "og-") ->
        base_url <> @post_images_path <> note.image_path

      # 2. Post has regular image (use as OG fallback)
      note.image_path ->
        base_url <> "/images/" <> note.image_path

      # 3. Category-specific OG image
      category = primary_category(note.tags) ->
        category_image_url(category, base_url)

      # 4. Default OG image
      true ->
        base_url <> @default_image
    end
  end

  def get_image_url(:blog, _opts) do
    BlogWeb.Endpoint.url() <> @default_image
  end

  def get_image_url(:page, data) when is_map(data) do
    base_url = BlogWeb.Endpoint.url()
    data[:image] || base_url <> @default_image
  end

  @doc """
  Returns OG image metadata for validators.
  """
  def image_metadata(url) do
    %{
      url: url,
      width: 1200,
      height: 630,
      alt: "Blog post cover image"
    }
  end

  # Private helpers

  defp primary_category(tags) when is_binary(tags) do
    tags
    |> String.split(",", trim: true)
    |> List.first()
    |> case do
      nil -> nil
      tag -> String.trim(tag)
    end
  end

  defp primary_category(_), do: nil

  defp category_image_url("elixir", base), do: base <> "/images/og-elixir.png"
  defp category_image_url("phoenix", base), do: base <> "/images/og-phoenix.png"
  defp category_image_url("tutorial", base), do: base <> "/images/og-tutorial.png"
  defp category_image_url(_, base), do: base <> @default_image

  @doc """
  Validates if an OG image meets social platform requirements.
  """
  def validate_image(image_path) do
    full_path = Path.join(["priv", "static", "images", image_path])

    with true <- File.exists?(full_path),
         {:ok, stat} <- File.stat(full_path),
         true <- stat.size < 300_000 do
      {:ok, "Image valid for OG"}
    else
      false -> {:error, "Image file not found"}
      {:ok, stat} -> {:error, "Image too large: #{stat.size} bytes (max 300KB)"}
      error -> error
    end
  end
end
