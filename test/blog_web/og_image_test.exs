defmodule BlogWeb.OGImageTest do
  use ExUnit.Case, async: true

  alias Blog.Note
  alias BlogWeb.OGImage

  test "returns post image when image_path exists" do
    url = OGImage.get_image_url(:post, %Note{image_path: "uploads/example.jpg", tags: "elixir"})

    assert url == BlogWeb.Endpoint.url() <> "/images/uploads/example.jpg"
  end

  test "falls back to default image when image_path is missing" do
    url = OGImage.get_image_url(:post, %Note{image_path: nil, tags: "phoenix"})

    assert url == BlogWeb.Endpoint.url() <> "/images/og-default.png"
  end

  test "falls back to default image even when tags are present" do
    url = OGImage.get_image_url(:post, %Note{image_path: "", tags: "tutorial"})

    assert url == BlogWeb.Endpoint.url() <> "/images/og-default.png"
  end
end
