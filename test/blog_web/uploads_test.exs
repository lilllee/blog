defmodule BlogWeb.UploadsTest do
  use ExUnit.Case, async: true

  alias BlogWeb.Uploads

  test "note_images_dir_for uses priv/static path for local database paths" do
    dir = Uploads.note_images_dir_for("priv/repo/dev.db")
    expected = Path.join([:code.priv_dir(:blog) |> to_string(), "static", "images", "uploads"])

    assert dir == expected
  end

  test "note_images_dir_for uses mounted uploads path for volume-backed database paths" do
    dir = Uploads.note_images_dir_for("/mnt/name/name.db")

    assert dir == "/mnt/name/uploads/images"
  end
end
