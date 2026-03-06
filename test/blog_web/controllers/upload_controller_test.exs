defmodule BlogWeb.UploadControllerTest do
  use BlogWeb.ConnCase, async: false

  alias BlogWeb.Router
  alias BlogWeb.Uploads

  setup do
    uploads_dir = Uploads.note_images_dir!()
    test_file = Path.join(uploads_dir, "controller-test.jpg")
    File.write!(test_file, "image-bytes")
    on_exit(fn -> File.rm(test_file) end)
    {:ok, test_file: test_file}
  end

  test "GET /images/uploads/*path serves an existing uploaded image" do
    conn = router_get("/images/uploads/controller-test.jpg")

    assert conn.status == 200
    assert [content_type] = get_resp_header(conn, "content-type")
    assert String.starts_with?(content_type, "image/jpeg")
    assert conn.resp_body == "image-bytes"
  end

  test "GET /images/uploads/*path returns 404 for missing files" do
    conn = router_get("/images/uploads/missing.jpg")

    assert conn.status == 404
    assert conn.resp_body == "Not found"
  end

  test "GET /images/uploads/*path rejects traversal attempts" do
    conn = router_get("/images/uploads/../../secrets.txt")

    assert conn.status == 404
    assert conn.resp_body == "Not found"
  end

  defp router_get(path) do
    "GET"
    |> Plug.Test.conn(path)
    |> Plug.Test.init_test_session(%{})
    |> Router.call(Router.init([]))
  end
end
