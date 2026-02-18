defmodule BlogWeb.PageControllerTest do
  use BlogWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ "JunHo&#39;s Blog"
  end
end
