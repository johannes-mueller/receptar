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
    @suggestion ".suggestion-container .suggestions a.suggestion"
    @input "input[name=\"title\"]"

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
      refute view |> has_element?(@form_selector <> ".suggestion-container")
    end

    test "initially search bar is empty", %{view: view} do
      refute view |> has_element?(@form_selector <> @input <> "[value=\"Granda kino\"]")
      assert view |> has_element?(@form_selector <> @input <> "[value=\"\"]")
    end

    test "typing `g` into the search bar makes `Granda kino` appear", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "g"})

      id = recipe_id("granda kino")

      selector = @suggestion <> "[href=\"/recipe/#{id}\"]"

      assert view
      |> element(@form_selector <> selector)
      |> render() =~ "<strong>G</strong>randa kino"
    end

    test "clearing search results in no suggestions", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "g"})

      view
      |> element(@form_selector)
      |> render_change(%{"title" => ""})

      refute view |> has_element?(@form_selector <> ".suggestions .suggestion")
    end

    test "typing `sa` into the search bar makes two recipes appear sa bold", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "sa"})

      for {search, title} <- [
	    {"tinusa bulko", "Tinu<strong>sa</strong> bulko"},
	    {"sardela pico", "<strong>Sa</strong>rdela pico"},
	  ] do

	  id = recipe_id(search)
	  selector = @suggestion <> "[href=\"/recipe/#{id}\"]"

	  assert view
	  |> element(@form_selector <> selector)
	  |> render() =~ title
      end
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
      |> render_change(%{"title" => "g"})

      id = recipe_id("granda kino")

      selector = @suggestion <> "[href=\"/recipe/#{id}\"]"

      assert view
      |> element(@form_selector <> selector)
      |> render() =~ "<strong>G</strong>roßes Kino"
    end
  end
end
