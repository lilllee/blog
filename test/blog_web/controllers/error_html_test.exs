defmodule BlogWeb.ErrorHTMLTest do
  use BlogWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    html = render_to_string(BlogWeb.ErrorHTML, "404", "html", [])

    assert html =~ "404 - Page Not Found"
    assert html =~ "Page not found"
    assert html =~ "Back to home"
  end

  test "renders 500.html" do
    html = render_to_string(BlogWeb.ErrorHTML, "500", "html", [])

    assert html =~ "500 - Server Error"
    assert html =~ "Something went wrong"
    assert html =~ "Back to home"
  end
end
