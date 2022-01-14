defmodule ReceptarWeb.PageControllerTest do
  import Receptar.AccountsFixtures

  use ReceptarWeb.ConnCase

  test "GET / at least one user registered", %{conn: conn} do
    admin_fixture()
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Receptar&#39; – The Multilingual Database for Recipes!"
  end

  test "GET / no user registered", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 302)
  end
end
