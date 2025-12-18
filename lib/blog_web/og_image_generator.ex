defmodule BlogWeb.OGImageGenerator do
  @moduledoc """
  Dynamic OG image generation for blog posts.

  ## Strategies:

  1. **ImageMagick** - Server-side generation (requires ImageMagick installed)
  2. **Cloudinary** - Cloud service (requires Cloudinary account)
  3. **Vercel OG** - Edge function (requires Vercel or Cloudflare)
  4. **Screenshot Service** - Puppeteer-based (requires headless Chrome)

  ## Current Implementation: ImageMagick (Local)
  """

  @output_dir "priv/static/images/og-generated"
  @template_path "priv/static/images/og-template.png"

  @doc """
  Generates an OG image for a blog post using ImageMagick.
  Returns the URL path to the generated image.

  ## Requirements
      brew install imagemagick  # macOS
      apt-get install imagemagick  # Ubuntu
  """
  def generate_for_post(note) do
    slug = note.slug || "post-#{note.id}"
    output_path = "#{@output_dir}/#{slug}.png"

    # Create output directory if not exists
    File.mkdir_p!(@output_dir)

    # Check if already generated
    if File.exists?(output_path) do
      {:ok, "/images/og-generated/#{slug}.png"}
    else
      case generate_image(note, output_path) do
        :ok -> {:ok, "/images/og-generated/#{slug}.png"}
        error -> error
      end
    end
  end

  defp generate_image(note, output_path) do
    title = truncate(note.title, 60)
    tags = format_tags(note.tags)
    date = format_date(note.published_at || note.inserted_at)

    # ImageMagick command to overlay text on template
    System.cmd("magick", [
      @template_path,
      "-gravity", "center",
      "-pointsize", "60",
      "-fill", "white",
      "-annotate", "+0-100", title,
      "-pointsize", "30",
      "-fill", "#94a3b8",
      "-annotate", "+0+50", tags,
      "-annotate", "+0+100", date,
      output_path
    ])
    |> case do
      {_, 0} -> :ok
      {error, _} -> {:error, "ImageMagick failed: #{error}"}
    end
  rescue
    e -> {:error, "Generation failed: #{Exception.message(e)}"}
  end

  @doc """
  Generates OG image using Cloudinary URL transformation.
  No server-side processing needed.
  """
  def cloudinary_url(note) do
    cloudinary_name = System.get_env("CLOUDINARY_CLOUD_NAME")
    base_image = "og-template.png"

    title = URI.encode(truncate(note.title, 60))

    "https://res.cloudinary.com/#{cloudinary_name}/image/upload/" <>
      "w_1200,h_630,c_fill/" <>
      "l_text:Arial_60_bold:#{title},co_rgb:ffffff,g_center,y_-100/" <>
      "#{base_image}"
  end

  @doc """
  Generates OG image using Vercel OG (edge function approach).
  Requires a Vercel function endpoint.
  """
  def vercel_og_url(note) do
    base_url = System.get_env("VERCEL_OG_ENDPOINT") || "https://og-image.vercel.app"

    title = URI.encode(note.title)

    "#{base_url}/#{title}.png?theme=dark&md=1&fontSize=100px"
  end

  # Helpers

  defp truncate(text, max_length) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length - 3) <> "..."
    else
      text
    end
  end

  defp format_tags(nil), do: ""
  defp format_tags(""), do: ""
  defp format_tags(tags) when is_binary(tags) do
    tags
    |> String.split(",", trim: true)
    |> Enum.take(3)
    |> Enum.map(&String.trim/1)
    |> Enum.join(" • ")
  end

  defp format_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%B %d, %Y")
  defp format_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%B %d, %Y")
  defp format_date(_), do: ""
end
