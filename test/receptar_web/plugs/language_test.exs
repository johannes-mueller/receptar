defmodule ReceptarWeb.Plugs.LanguageTest do
  use ReceptarWeb.ConnCase

  describe "language plug" do

    test "defaults to 'eo'", %{conn: conn} do
      conn = conn
      |> get("/")

      assert get_session(conn, "language") == "eo"
      assert conn.assigns.language == "eo"
    end

    for language <- ["de", "sk"] do
      test "overrides from language parameter #{language}", %{conn: conn} do
	language = unquote(language)
	conn = conn
	|> get("/?language=" <> language)

	assert get_session(conn, "language") == language
	assert conn.assigns.language == language
      end

      test "overrides from session language parameter #{language}", %{conn: conn} do
	language = unquote(language)
	conn = conn
	|> Phoenix.ConnTest.init_test_session(%{})
	|> put_session("language", language)
	|> get("/")

	assert get_session(conn, "language") == language
	assert conn.assigns.language == language
      end
    end
  end
end
