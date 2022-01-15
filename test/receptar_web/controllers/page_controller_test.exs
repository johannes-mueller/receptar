defmodule ReceptarWeb.PageControllerTest do
  import Receptar.AccountsFixtures

  use ReceptarWeb.ConnCase

  describe "admin user registered" do
    setup %{conn: conn} do
      admin_fixture()
      %{conn: conn}
    end

    test "GET / at least one user registered", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Receptar&#39; – The Multilingual Database for Recipes!"
    end
  end

  test "GET / no user registered", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 302) =~ ~r|href="/users/register"|
  end

end
