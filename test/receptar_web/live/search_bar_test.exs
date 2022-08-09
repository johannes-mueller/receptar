defmodule ReceptarWeb.SearchBarTest do
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Phoenix.LiveViewTest

  import Receptar.Seeder
  import Receptar.TestHelpers

  alias ReceptarWeb.SearchBar

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
      assert view |> has_element?(@form_selector)
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

    test "blurring search input results in no suggestions", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "g"})

      view
      |> element(@form_selector <> @input)
      |> render_blur(%{"value" => "g"})

      refute view |> has_element?(@form_selector <> ".suggestions .suggestion")
    end

    test "blurring search input keeps the input value", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "foo"})

      view
      |> element(@form_selector <> @input)
      |> render_blur(%{"value" => "foo"})

      assert view |> has_element?(@form_selector <> @input <> "[value=\"foo\"]")
    end

    test "refocusing search input results brings back suggestions", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "g"})

      view
      |> element(@form_selector <> @input)
      |> render_blur(%{"value" => "g"})

      view
      |> element(@form_selector <> @input)
      |> render_focus()

      assert view |> has_element?(@form_selector <> ".suggestions .suggestion")
    end

    test "typing `sa` into the search bar makes two recipes appear sa bold", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "sa"})

      for {search, title} <- [
	    {"sardela pico", "<strong>Sa</strong>rdela pico"},
	    {"tinusa bulko", "Tinu<strong>sa</strong> bulko"},
	  ] do

	  id = recipe_id(search)
	  selector = @suggestion <> "[href=\"/recipe/#{id}\"]"

	  assert view
	  |> element(@form_selector <> selector)
	  |> render() =~ title
      end
    end

    test "hitting arrow down with no suggestions does not fail", %{view: view} do
      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})
    end

    test "hitting arrow up with no suggestions does not fail", %{view: view} do
      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowUp"})
    end

    test "hitting a letter key on search bar does not fail", %{view: view} do
      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "a"})
    end

    test "hitting arrow down once on search bar form focuses first suggestion", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "s"})

      id = recipe_id("sardela pico")
      element_id = "suggestion-#{id}"

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      assert_push_event(view, "focus-element", %{id: ^element_id})
    end

    test "hitting arrow down once on search bar input focuses first suggestion", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "s"})

      id = recipe_id("sardela pico")
      element_id = "suggestion-#{id}"

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      assert_push_event(view, "focus-element", %{id: ^element_id})
    end

    test "hitting arrow down twice focuses second suggestion", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "sa"})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      id = recipe_id("tinusa bulko")
      element_id = "suggestion-#{id}"

      assert_push_event(view, "focus-element", %{id: ^element_id})
    end

    test "hitting arrow down once and arrow up once focuses input", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "sa"})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      id = recipe_id("sardela pico")
      element_id = "suggestion-#{id}"

      assert_push_event(view, "focus-element", %{id: ^element_id})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowUp"})

      assert_push_event(view, "focus-element", %{id: "search-bar-input"})
    end

    test "hitting arrow down twice and arrow up once focuses first suggestion", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "sa"})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      id = recipe_id("sardela pico")
      element_id = "suggestion-#{id}"

      assert_push_event(view, "focus-element", %{id: ^element_id})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowUp"})

      assert_push_event(view, "focus-element", %{id: ^element_id})
    end

    test "hitting arrow down beyond suggestions focuses last suggestion", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "sa"})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      element_id = "suggestion-#{recipe_id("sardela pico")}"
      assert_push_event(view, "focus-element", %{id: ^element_id})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      element_id = "suggestion-#{recipe_id("tinusa bulko")}"
      assert_push_event(view, "focus-element", %{id: ^element_id})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      element_id = "suggestion-#{recipe_id("tinusa bulko")}"
      assert_push_event(view, "focus-element", %{id: ^element_id})
    end

    test "hitting arrow down beyond suggestions and arrow up focuses before last suggestion", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "sa"})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      element_id = "suggestion-#{recipe_id("sardela pico")}"
      assert_push_event(view, "focus-element", %{id: ^element_id})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      element_id = "suggestion-#{recipe_id("tinusa bulko")}"
      assert_push_event(view, "focus-element", %{id: ^element_id})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowUp"})

      element_id = "suggestion-#{recipe_id("sardela pico")}"
      assert_push_event(view, "focus-element", %{id: ^element_id})
    end

    test "hitting arrow down changing input and hitting arrow down focuses first suggestion", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "g"})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      assert_push_event(view, "focus-element", %{})

      view
      |> element(@form_selector)
      |> render_change(%{"title" => "sa"})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      element_id = "suggestion-#{recipe_id("sardela pico")}"
      assert_push_event(view, "focus-element", %{id: ^element_id})
    end

    test "hitting arrow down blurring refocusing and hitting arrow down focuses first suggestion", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "sa"})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      assert_push_event(view, "focus-element", %{})

      view
      |> element(@form_selector <> @input)
      |> render_blur()
      view
      |> element(@form_selector <> @input)
      |> render_focus()

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      element_id = "suggestion-#{recipe_id("sardela pico")}"
      assert_push_event(view, "focus-element", %{id: ^element_id})
    end

    test "blurring search input when suggestion focused keeps suggestions", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "sa"})

      view
      |> element(@form_selector)
      |> render_keydown(%{"key" => "ArrowDown"})

      view
      |> element(@form_selector <> @input)
      |> render_blur(%{"value" => "sa"})

      assert view |> has_element?(@form_selector <> ".suggestions .suggestion")
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
