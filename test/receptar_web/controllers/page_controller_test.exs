defmodule ReceptarWeb.PageControllerTest do
  use ReceptarWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Receptar&#39; – The Multilingual Database for Recipes!"
  end
end
