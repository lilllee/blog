defmodule BlogWeb.OGImage do
  @moduledoc """
  Open Graph image helper for social sharing optimization.
  Uses explicit post images when available and falls back to the default image.
  """

  @default_image "/images/og-default.png"

  @doc """
  Returns the best OG image URL for the given content.
  Tries in order: explicit post image → default.
  """
  def get_image_url(type, data \\ %{})

  def get_image_url(:post, note) when is_map(note) do
    base_url = BlogWeb.Endpoint.url()

    if is_binary(note.image_path) and note.image_path != "" do
      base_url <> "/images/" <> note.image_path
    else
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
