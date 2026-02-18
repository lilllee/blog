defmodule BlogWeb.Uploads do
  @moduledoc false

  @note_image_subdir Path.join(["static", "images", "uploads"])
  @audio_subdir Path.join(["static", "uploads", "audio"])
  @allowed_exts ~w(.jpg .jpeg .png .gif .webp)
  @allowed_audio_exts ~w(.mp3 .wav .m4a .ogg)

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

  def store_audio_file!(%{path: temp_path}, %{client_name: client_name}) do
    ext = client_name |> Path.extname() |> String.downcase()

    if ext not in @allowed_audio_exts do
      raise ArgumentError, "unsupported audio extension: #{inspect(ext)}"
    end

    filename = unique_filename(ext)
    dest_dir = audio_dir!()
    dest_path = Path.join(dest_dir, filename)

    File.cp!(temp_path, dest_path)

    Path.join(["uploads", "audio", filename])
  end

  def note_images_dir! do
    dir = Path.join([priv_dir(), @note_image_subdir])
    File.mkdir_p!(dir)
    dir
  end

  def audio_dir! do
    dir = resolve_audio_dir()
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

  defp resolve_audio_dir do
    case System.get_env("AUDIO_UPLOADS_DIR") do
      nil ->
        default_audio_dir()

      "" ->
        default_audio_dir()

      path ->
        path
    end
  end

  defp default_audio_dir do
    case System.get_env("DATABASE_PATH") do
      path when is_binary(path) and path != "" ->
        expanded_path = Path.expand(path)

        if String.starts_with?(expanded_path, "/mnt/") do
          expanded_path
          |> Path.dirname()
          |> Path.join(Path.join("uploads", "audio"))
        else
          Path.join([priv_dir(), @audio_subdir])
        end

      _ ->
        Path.join([priv_dir(), @audio_subdir])
    end
  end
end
