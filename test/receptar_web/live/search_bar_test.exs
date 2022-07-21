defmodule ReceptarWeb.SearchBarTest do
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Phoenix.LiveViewTest

  import Receptar.Seeder
  import Receptar.TestHelpers

  alias ReceptarWeb.SearchBar

  # describe "Socket state" do
  #   setup do
  #     insert_test_data()

  #     {:ok, socket, layout: false} =
  # 	SearchBar.mount(
  # 	  %{},
  # 	  %{"language" => "eo"},
  # 	  %Phoenix.LiveView.Socket{}
  # 	)

  #     %{socket: socket}
  #   end

  #   test "initially suggestions are empty", %{socket: socket} do
  #     assert socket.assigns.suggestions == []
  #   end

  #   # test "typing `granda` into the search bar returns [`Granda kino`]", %{socket: socket} do

  #   # end
  # end

  describe "Connection state" do
    @form_selector "form[action=\"/search\"][method=\"get\"] "
    @suggestion ".suggestions .suggestion[phx-click=\"choose-suggestion\"]"
    @input "input[name=\"search-string\"]"

    setup %{conn: conn} do
      insert_test_data()
      %{conn: conn} = register_and_log_in_user(%{conn: conn})

      session = %{"language" => "eo"}

      {:ok, view, _html} = live_isolated(conn, SearchBar, session: session)
      %{view: view}
    end

    test "search bar has a form which triggers a search", %{view: view} do
      assert view |> has_element?("form[action=\"/search\"][method=\"get\"]")
    end

    test "initially no suggestion divs are rendered", %{view: view} do
      refute view |> has_element?(@form_selector <> ".suggestions .suggestion")
    end

    test "initially search bar is empty", %{view: view} do
      refute view |> has_element?(@form_selector <> @input <> "[value=\"Granda kino\"]")
      assert view |> has_element?(@form_selector <> @input <> "[value=\"\"]")
    end

    test "typing `g` into the search bar makes `Granda kino` appear", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"search-string" => "g"})

      id = recipe_id("granda kino")

      selector = @suggestion <> "[phx-value-recipe-id=\"#{id}\"]"

      assert view
      |> element(@form_selector <> selector)
      |> render() =~ "Granda kino"
    end

    test "clearing search results in no suggestions", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"search-string" => "g"})

      view
      |> element(@form_selector)
      |> render_change(%{"search-string" => ""})

      refute view |> has_element?(@form_selector <> ".suggestions .suggestion")
    end

    test "typing `g` puts `Granda kino` into search bar", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"search-string" => "g"})

      refute view |> has_element?(@form_selector <> @input <> "[value=\"\"]")
      assert view |> has_element?(@form_selector <> @input <> "[value=\"Granda kino\"]")
    end

    test "typing `s` into the search bar makes two recipes appear", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"search-string" => "s"})

      for {search, title} <- [
	    {"sardela pico", "Sardela pico"},
	    {"sukera bulko", "Sukera bulko"},
	    {"tinusa bulko", "Tinusa bulko"}
	  ] do

	  id = recipe_id(search)
	  selector = @suggestion <> "[phx-value-recipe-id=\"#{id}\"]"

	  assert view
	  |> element(@form_selector <> selector)
	  |> render() =~ title
      end
    end

    test "typing `p` puts `Penne ` into search bar", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"search-string" => "p"})

      refute view |> has_element?(@form_selector <> @input <> "[value=\"\"]")
      assert view |> has_element?(@form_selector <> @input <> "[value=\"Penne \"]")
    end

  end

  describe "Connection state in german" do
    setup %{conn: conn} do
      insert_test_data()
      %{conn: conn} = register_and_log_in_user(%{conn: conn})

      session = %{"language" => "de"}

      {:ok, view, _html} = live_isolated(conn, SearchBar, session: session)
      %{view: view}
    end

    test "typing `g` into the search bar makes `Großes Kino` appear", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"search-string" => "g"})

      id = recipe_id("granda kino")

      selector = @suggestion <> "[phx-value-recipe-id=\"#{id}\"]"

      assert view
      |> element(@form_selector <> selector)
      |> render() =~ "Großes Kino"
    end
  end
end
