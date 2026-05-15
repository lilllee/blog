defmodule BlogWeb.Uploads do
  @moduledoc false

  @note_image_subdir Path.join(["static", "images", "uploads"])
  @mounted_note_image_subdir Path.join(["uploads", "images"])
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
    dir = resolve_note_images_dir()
    File.mkdir_p!(dir)
    dir
  end

  def resolve_note_image_path(relative_path) do
    resolve_uploaded_path(relative_path, note_images_dir!())
  end

  def note_images_dir_for(database_path) do
    case database_path do
      path when is_binary(path) and path != "" ->
        expanded_path = Path.expand(path)

        if String.starts_with?(expanded_path, "/mnt/") do
          expanded_path
          |> Path.dirname()
          |> Path.join(@mounted_note_image_subdir)
        else
          Path.join([priv_dir(), @note_image_subdir])
        end

      _ ->
        Path.join([priv_dir(), @note_image_subdir])
    end
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

  defp resolve_note_images_dir do
    System.get_env("DATABASE_PATH")
    |> note_images_dir_for()
  end

  defp resolve_uploaded_path(relative_path, base_dir) do
    if invalid_path?(relative_path) do
      :error
    else
      base_dir = Path.expand(base_dir)
      candidate = Path.expand(Path.join(base_dir, relative_path))

      if String.starts_with?(candidate, base_dir <> "/") and File.regular?(candidate) do
        {:ok, candidate}
      else
        :error
      end
    end
  end

  defp invalid_path?(path) do
    path == "" or String.starts_with?(path, "/") or String.contains?(path, "..")
  end
end
