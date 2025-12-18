defmodule BlogWeb.Uploads do
  @moduledoc false

  @note_image_subdir Path.join(["static", "images", "uploads"])
  @allowed_exts ~w(.jpg .jpeg .png .gif .webp)

  def store_note_image!(%{path: temp_path}, %{client_name: client_name}) do
    ext = client_name |> Path.extname() |> String.downcase()

    if ext not in @allowed_exts do
      raise ArgumentError, "unsupported image extension: #{inspect(ext)}"
    end

    filename = unique_filename(ext)
    dest_dir = note_images_dir!()
    dest_path = Path.join(dest_dir, filename)

    File.cp!(temp_path, dest_path)

    Path.join("uploads", filename)
  end

  def note_images_dir! do
    dir = Path.join([priv_dir(), @note_image_subdir])
    File.mkdir_p!(dir)
    dir
  end

  defp priv_dir do
    :blog
    |> :code.priv_dir()
    |> to_string()
  end

  defp unique_filename(ext) do
    token = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    token <> ext
  end
end

