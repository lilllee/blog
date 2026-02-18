defmodule BlogWeb.UploadController do
  use BlogWeb, :controller

  alias BlogWeb.Uploads

  def audio(conn, %{"path" => path_parts}) when is_list(path_parts) do
    relative_path = Path.join(path_parts)

    case resolve_audio_path(relative_path) do
      {:ok, full_path} ->
        conn
        |> put_resp_content_type(MIME.from_path(full_path))
        |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
        |> send_file(200, full_path)

      :error ->
        send_resp(conn, 404, "Not found")
    end
  end

  def audio(conn, _params), do: send_resp(conn, 404, "Not found")

  defp resolve_audio_path(relative_path) do
    if invalid_path?(relative_path) do
      :error
    else
      base_dir = Uploads.audio_dir!() |> Path.expand()
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
