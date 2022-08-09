defmodule ReceptarWeb.RecipeControllerTest do
  use ReceptarWeb.ConnCase

  import Receptar.Seeder
  import Receptar.TestHelpers

  describe "sample database available" do
    setup %{conn: conn} do
      insert_test_data()
      register_and_log_in_user(%{conn: conn})
    end

    test "show unknown recipe returns 404", %{conn: conn} do
      assert_error_sent(404, fn -> get(conn, "/recipe/2342") end)
    end

    for {url_function, target} <- [{&recipe_url/1, "edit"}] do
      test "#{target} recipe id 1 has title page 'Granda kino'", %{conn: conn} do
	conn = get(conn, unquote(url_function).("granda kino"))
	assert html_response_stripped(conn, 200) =~ ~r/<h1.*> *Granda kino *<\/h1>/
	refute html_response_stripped(conn, 200) =~ ~r/<h1.*> *Sardela pico *<\/h1>/
	refute html_response_stripped(conn, 200) =~ ~r/<h1.*> *Großes Kino *<\/h1>/
      end

      test "#{target} recipe id 1 in German has title page 'Großes Kino'", %{conn: conn} do
	conn = get(conn, unquote(url_function).("granda_kino") <> "?language=de")
	assert html_response_stripped(conn, 200) =~ ~r/<h1.*> *Großes Kino *<\/h1>/
	refute html_response_stripped(conn, 200) =~ ~r/<h1.*> *Granda kino *<\/h1>/
      end

      test "#{target} recipe granda kino is for 2 servings", %{conn: conn} do
	conn = get(conn, unquote(url_function).("granda_kino") <> "?language=de")
	assert html_response_stripped(conn, 200) =~ ~r|<span>For</span><span>2 servings.</span>|
      end

      test "#{target} recipe sardela pico is for 1 servings", %{conn: conn} do
	conn = get(conn, unquote(url_function).("sardela pico") <> "?language=de")
	assert html_response_stripped(conn, 200) =~ ~r|<span>For</span><span>one serving\.</span>|
      end

      test "#{target} recipe id 1 \"de\"  session German title", %{conn: conn} do
	conn =
	  conn
	  |> Phoenix.ConnTest.init_test_session(%{})
	  |> put_session(:language, "de")
	  |> get(unquote(url_function).("granda_kino"))

	assert html_response_stripped(conn, 200) =~ ~r/<h1.*> *Großes Kino *<\/h1>/
	refute html_response_stripped(conn, 200) =~ ~r/<h1.*> *Granda kino *<\/h1>/
      end

      test "#{target} recipe id 1 has title page 'Sardela pico'", %{conn: conn} do
	conn = get(conn, unquote(url_function).("sardela pico"))
	refute html_response_stripped(conn, 200) =~ ~r/<h1.*> *Granda kino *<\/h1>/
	assert html_response_stripped(conn, 200) =~ ~r/<h1.*> *Sardela pico *<\/h1>/
      end

      test "#{target} recipe 1 has an class-ingredients-list <ul> tag", %{conn: conn} do
	conn = get(conn, unquote(url_function).("granda kino"))
	assert html_response(conn, 200) =~ "<ul class=\"ingredients-list\">"
      end

      test "#{target} recipe 1 has an class-instructions-list <ul> tag", %{conn: conn} do
	conn = get(conn, unquote(url_function).("granda kino"))
	assert html_response(conn, 200) =~ "<ul class=\"instructions-list\">"
      end

      test "#{target} recipe 1 in Esperanto has an ingredients entry for nudeloj", %{conn: conn} do
	conn = get(conn, unquote(url_function).("granda kino"))
	assert html_response(conn, 200) =~ "nudeloj"
	refute html_response(conn, 200) =~ "pasto"
      end

      test "#{target} recipe 2 in Esperanto has an ingredients entry for pasto", %{conn: conn} do
	conn = get(conn, unquote(url_function).("sardela pico"))
	assert html_response(conn, 200) =~ "pasto"
	refute html_response(conn, 200) =~ "nudeloj"
      end

      test "#{target} recipe 1 in German has an ingredients entry for Pasta", %{conn: conn} do
	conn = get(conn, unquote(url_function).("granda kino") <> "?language=de")
	refute html_response(conn, 200) =~ "nudeloj"
	assert html_response(conn, 200) =~ "Pasta"
      end

      test "#{target} recipe 1 in Esperanto has two ordered instructions", %{conn: conn} do
	conn = get(conn, unquote(url_function).("granda kino"))
	assert html_response_stripped(conn, 200) =~ ~r/kuiri nudelojn.*aldoni tinuson/
      end

      test "#{target} instructions in class-instruction-list-entry <li>", %{conn: conn} do
	conn = get(conn, unquote(url_function).("granda kino"))
	assert html_response_stripped(conn, 200) =~
	  ~r/<li class="instruction-list-entry editable-item">.*kuiri nudelojn.*<\/li>/
      end

      test "#{target} recipe 1 in German has translation missing tag", %{conn: conn} do
	conn = get(conn, unquote(url_function).("granda kino") <> "?language=de")
	assert html_response_stripped(conn, 200) =~ ~r/class="translation-missing"/
      end
    end

    test "create recipe redirects to live view", %{conn: conn} do
      recipe_title = %{title: "Granda kino"}
      conn = post(conn, Routes.recipe_path(conn, :create), recipe_title)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn, 302) == "/recipe/#{id}"
    end

    test "create recipe empty title redirects to new", %{conn: conn} do
      recipe_title = %{title: ""}
      conn = post(conn, Routes.recipe_path(conn, :create), recipe_title)
      assert html_response(conn, 200) =~ "Enter new recipe title"
    end

    for language <- ["eo", "de"] do
      test "created recipe in #{language} is found in db", %{conn: conn} do
	language = unquote(language)
	recipe_title = %{title: "foobar"}
	conn
	|> Phoenix.ConnTest.init_test_session(%{})
	|> put_session(:language, language)
	|> post(Routes.recipe_path(conn, :create), recipe_title)

	recipe = recipe_by_title("foobar", language)
	assert recipe
      end
    end

  end

  test "search form redirect if no user authenticated", %{conn: conn} do
    conn = get(conn, "/search")

    assert redirected_to(conn) == "/users/log_in"
  end
end
