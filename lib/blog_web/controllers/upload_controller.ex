defmodule BlogWeb.UploadController do
  use BlogWeb, :controller

  alias BlogWeb.Uploads

  def image(conn, %{"path" => path_parts}) when is_list(path_parts) do
    path_parts
    |> Path.join()
    |> Uploads.resolve_note_image_path()
    |> send_upload(conn)
  end

  def image(conn, _params), do: send_resp(conn, 404, "Not found")

  defp send_upload({:ok, full_path}, conn) do
    conn
    |> put_resp_content_type(MIME.from_path(full_path))
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> send_file(200, full_path)
  end

  defp send_upload(:error, conn), do: send_resp(conn, 404, "Not found")
end
