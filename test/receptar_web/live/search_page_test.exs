defmodule ReceptarWeb.SearchOageTest do
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Phoenix.LiveViewTest

  import Receptar.Seeder
  import Receptar.TestHelpers

  @form_selector "form[action=\"/search\"][method=\"get\"] "
  @search_hit "table tr td.recipe-title-link a"
  @substance_search "form[phx-change=\"search-substance\"]"
  @class_selector "input[form=\"main-search-form\"][type=\"radio\"][name=\"class\"]"

  describe "Connection state empty form" do
    setup %{conn: conn} do
      insert_test_data()
      conn = init_test_session(conn, %{"language" => "eo"})
      %{conn: conn} = register_and_log_in_user(%{conn: conn})

      {:ok, view, _html} = live(conn, "/search")
      %{view: view}
    end

    test "search page has form which triggers a search", %{view: view} do
      assert view |> has_element?(@form_selector)
    end

    test "search page has an empty input field for title in the form", %{view: view} do
      assert view |> has_element?(@form_selector <> "input[name=title][value=\"\"]")
    end

    test "initially all 8 search results are available", %{view: view} do
      expected_number = length(Receptar.Recipes.search(%{}, language: "eo"))

      assert view |> has_element?("tr:nth-of-type(#{expected_number})")
      refute view |> has_element?("tr:nth-of-type(#{expected_number + 1})")
    end

    test "initially no substances checkbox available in the form", %{view: view} do
      refute view |> has_element?("input[type=\"checkbox\"][name=\"substance[]\"]")
    end

    test "typing `g` into the search bar makes `Granda kino` appear", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "g"})

      id = recipe_id("granda kino")

      html = view
      |> element(@search_hit <> "[href=\"/recipe/#{id}\"]")
      |> render()

      assert html =~ "<strong>G</strong>randa kino"
      refute html =~ "<strong>G</strong>roßes Kino"
    end

    test "typing `granda` into the search bar pushes url to ?title=granda", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"_target" => "title", "title" => "granda"})

      view |> assert_patched("/search?title=granda")
    end

    test "has an input so look for substances", %{view: view} do
      assert view |> has_element?(@substance_search)
    end

    test "typing 'ti' into the substance search field makes unchecked 'tinuso' appear", %{view: view} do
      view
      |> element(@substance_search)
      |> render_change(%{"search_string" => "ti"})

      sid_1 = substance_by_name("tinuso").id

      e1 = "input#substance-#{sid_1}[type=\"checkbox\"][name=\"substance[]\"][value=#{sid_1}]"

      assert view |> has_element?(e1)
      refute view |> has_element?(e1 <> "[checked]")
    end

    test "typing 'ti' and then 'nu' makes 'tinuso' appear only once", %{view: view} do
      view
      |> element(@substance_search)
      |> render_change(%{"search_string" => "ti"})
      view
      |> element(@substance_search)
      |> render_change(%{"search_string" => "tinu"})

      assert view |> has_element?("div.shown-substance")
      refute view |> has_element?("div.shown-substance:nth-of-type(2)")
    end

    test "typing 'sa' and then 'lo' search makes 'sardeloj' disappear", %{view: view} do
      view
      |> element(@substance_search)
      |> render_change(%{"search_string" => "sa"})
      view
      |> element(@substance_search)
      |> render_change(%{"search_string" => "salo"})

      sid = substance_by_name("sardeloj").id
      element = "input[value=#{sid}]"

      refute view |> has_element?(element)
    end

    test "typing 'sa' and then erasing search makes all disappear", %{view: view} do
      view
      |> element(@substance_search)
      |> render_change(%{"search_string" => "sa"})
      view
      |> element(@substance_search)
      |> render_change(%{"search_string" => ""})

      refute view |> has_element?("input[name=\"substance[]\"]")
    end

    test "type 'to' select 'lakto' type 's' and 'sa' only one checbox for salo", %{view: view} do
      view
      |> element(@substance_search)
      |> render_change(%{"search_string" => "to"})
      view
      |> element(@form_selector)
      |> render_change(%{"substance[]" => substance_by_name("pasto").id})
      view
      |> element(@substance_search)
      |> render_change(%{"search_string" => "s"})
      view
      |> element(@substance_search)
      |> render_change(%{"search_string" => "sa"})

      refute view |> has_element?("input[name=\"substance\"]:nth-of-type(2)")
    end

    test "class selector 'vegan' is available", %{view: view} do
      assert view |> has_element?(@class_selector <> "[value=\"vegan\"]")
    end

    test "class selector 'vegetarian' is available", %{view: view} do
      assert view |> has_element?(@class_selector <> "[value=\"vegetarian\"]")
    end

    test "class selector 'all' is available", %{view: view} do
      assert view |> has_element?(@class_selector <> "[value=\"all\"]")
    end

    test "only class selector 'all' is checked by default", %{view: view} do
      assert view |> has_element?(@class_selector <> "[value=\"all\"][checked]")
      refute view |> has_element?(@class_selector <> "[value=\"vegan\"][checked]")
      refute view |> has_element?(@class_selector <> "[value=\"vegetarian\"][checked]")
    end

    test "selecting 'vegan' makes 'vegan' radio checked", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"class" => "vegan"})

      assert view |> has_element?(@class_selector <> "[value=\"vegan\"][checked]")
      refute view |> has_element?(@class_selector <> "[value=\"vegetarian\"][checked]")
      refute view |> has_element?(@class_selector <> "[value=\"all\"][checked]")
    end

    test "selecting 'vegetarian' makes 'vegetarian' radio checked", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"class" => "vegetarian"})

      assert view |> has_element?(@class_selector <> "[value=\"vegetarian\"][checked]")
      refute view |> has_element?(@class_selector <> "[value=\"vegan\"][checked]")
      refute view |> has_element?(@class_selector <> "[value=\"all\"][checked]")
    end

    test "selecting class 'all' does not make class=all appear in the uri", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"class" => "all"})

      view |> assert_patched("/search?title=")
    end
  end


  describe "Connection state empty form in german" do
    setup %{conn: conn} do
      insert_test_data()
      conn = init_test_session(conn, %{"language" => "de"})
      %{conn: conn} = register_and_log_in_user(%{conn: conn})

      {:ok, view, _html} = live(conn, "/search")
      %{view: view}
    end

    test "initially all search results are available", %{view: view} do
      html = view |> element("table") |> render

      assert html =~ "Großes Kino"
      assert html =~ "Thunfischbrötchen"
    end

    test "typing `g` into the search bar makes `Großes Kino` appear", %{view: view} do
      view
      |> element(@form_selector)
      |> render_change(%{"title" => "g"})

      id = recipe_id("granda kino")

      html = view
      |> element(@search_hit <> "[href=\"/recipe/#{id}\"]")
      |> render()

      assert html =~ "<strong>G</strong>roßes Kino"
      refute html =~ "<strong>G</strong>randa kino"
    end
  end

  describe "Connection state prefilled form" do
    setup %{conn: conn} do
      insert_test_data()
      conn = init_test_session(conn, %{"language" => "eo"})
      register_and_log_in_user(%{conn: conn})
    end

    test "title search 'sa' has two hits", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/search?title=sa")

      assert view |> has_element?("tr:nth-of-type(2)")
      refute view |> has_element?("tr:nth-of-type(3)")
    end

    test "title search 'foobar' has no hits", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/search?title=foobar")

      refute view |> has_element?(@search_hit)
    end

    test "title search 'foobar' renders 'One recipe found'", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/search?title=foobar")

      assert view |> element("h2#search-results-heading") |> render() =~ "No recipes found"
    end

    test "title search 'foobar' renders 'No recipes found'", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/search?title=foobar")

      assert view |> element("h2#search-results-heading") |> render() =~ "No recipes found"
    end

    test "title search 'granda' renders 'One recipes found'", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/search?title=granda")

      assert view |> element("h2#search-results-heading") |> render() =~ "One recipe found"
    end

    test "title search 'sa' renders 'Two recipes found'", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/search?title=sa")

      assert view |> element("h2#search-results-heading") |> render() =~ "2 recipes found"
    end

    test "title search 'foo' leads to prefilled title search", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/search?title=foo")

      assert view |> has_element?("input[name=\"title\"][value=\"foo\"]")
    end

    test "substance search 'tinuso' finds 2 recipes", %{conn: conn} do
      sid = substance_by_name("tinuso").id
      {:ok, view, _html} = live(conn, "/search?substance[]=#{sid}")

      assert view |> element("h2#search-results-heading") |> render() =~ "2 recipes found"
    end

    test "checkbox of preselected substances appear", %{conn: conn} do
      sid_1 = substance_by_name("tinuso").id
      sid_2 = substance_by_name("nudeloj").id
      {:ok, view, _html} = live(conn, "/search?substance[]=#{sid_1}&substance[]=#{sid_2}")

      e1 = "input#substance-#{sid_1}[type=\"checkbox\"][name=\"substance[]\"][value=#{sid_1}][checked]"
      e2 = "input#substance-#{sid_2}[type=\"checkbox\"][name=\"substance[]\"][value=#{sid_2}][checked]"
      assert view |> has_element?(e1)
      assert view |> has_element?(e2)

      assert view |> element("label[for=substance-#{sid_1}]") |> render =~ "tinuso"
      assert view |> element("label[for=substance-#{sid_2}]") |> render =~ "nudeloj"
    end

    test "unchecking preselected substance leaves checkbox unchecked", %{conn: conn} do
      sid_1 = substance_by_name("tinuso").id
      sid_2 = substance_by_name("nudeloj").id
      {:ok, view, _html} = live(conn, "/search?substance[]=#{sid_1}&substance[]=#{sid_2}")

      e1 = "input#substance-#{sid_1}[type=\"checkbox\"][name=\"substance[]\"][value=#{sid_1}]"
      e2 = "input#substance-#{sid_2}[type=\"checkbox\"][name=\"substance[]\"][value=#{sid_2}]"

      view |> element(@form_selector) |> render_change(%{"substance" => [sid_2]})

      assert view |> has_element?(e1)
      refute view |> has_element?(e1 <> "[checked]")
      assert view |> has_element?(e2 <> "[checked]")
    end

    test "unchecking preselected substance and checking again leads to all checked", %{conn: conn} do
      sid_1 = substance_by_name("tinuso").id
      sid_2 = substance_by_name("nudeloj").id
      {:ok, view, _html} = live(conn, "/search?substance[]=#{sid_1}&substance[]=#{sid_2}")

      e1 = "input#substance-#{sid_1}[type=\"checkbox\"][name=\"substance[]\"][value=#{sid_1}]"
      e2 = "input#substance-#{sid_2}[type=\"checkbox\"][name=\"substance[]\"][value=#{sid_2}]"

      view |> element(@form_selector) |> render_change(%{"substance" => [sid_2]})
      view |> element(@form_selector) |> render_change(%{"substance" => [sid_1, sid_2]})

      assert view |> has_element?(e1 <> "[checked]")
      assert view |> has_element?(e2 <> "[checked]")
    end

    test "uncheck last preselected substance leaves checkbox unchecked", %{conn: conn} do
      sid = substance_by_name("tinuso").id
      {:ok, view, _html} = live(conn, "/search?substance[]=#{sid}")

      view |> element(@form_selector) |> render_change(%{})

      assert view |> has_element?("input#substance-#{sid}")
      refute view |> has_element?("input#substance-#{sid}[checked]")
    end

    test "search an already selected substance does not make it appear twice", %{conn: conn} do
      sid = substance_by_name("tinuso").id
      {:ok, view, _html} = live(conn, "/search?substance[]=#{sid}")

      view
      |> element(@substance_search)
      |> render_change(%{"search_string" => "ti"})

      e1 = "input#substance-#{sid}[type=\"checkbox\"][name=\"substance[]\"][value=#{sid}]"

      assert view |> has_element?(e1)
      refute view |> has_element?(e1 <> ":not([checked])")
    end

    test "invalid string substance id does not fail", %{conn: conn} do
      {:ok, _view, _html} = live(conn, "/search?substance[]=foobar")
    end

    test "invalid float substance id does not fail", %{conn: conn} do
      {:ok, _view, _html} = live(conn, "/search?substance[]=3.14")
    end

    test "invalidly formed substance query does not fail", %{conn: conn} do
      {:ok, _view, _html} = live(conn, "/search?substance[foo]=3.14")
    end

    test "nonexisting substance does not fail", %{conn: conn} do
      {:ok, _view, _html} = live(conn, "/search?substance[]=0")
    end

    test "no list substance param does not fail", %{conn: conn} do
      {:ok, _view, _html} = live(conn, "/search?substance=1")
    end

    test "unknown search parameter does not fail", %{conn: conn} do
      {:ok, _view, _html} = live(conn, "/search?foo=bar")
    end

    test "render recipe description for granda kino", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/search?title=granda")

      assert view
      |> element("td.recipe-description-search")
      |> render() =~ "Vere granda kino"
      refute view
      |> element("td.recipe-description-search")
      |> render() =~ "Bedaŭrinde ne ĉiam havebla"
    end

    test "render recipe description for sukera bulko", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/search?title=sukera")

      assert view
      |> element("td.recipe-description-search")
      |> render() =~ "Bedaŭrinde ne ĉiam havebla"
      refute view
      |> element("td.recipe-description-search")
      |> render() =~ "Vere granda kino"
    end

    test "render recipe reference for granda kino", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/search?title=granda")

      assert view
      |> element("td.recipe-reference-search")
      |> render() =~ "ia podkasto"
      refute view
      |> element("td.recipe-reference-search")
      |> render() =~ "https://sukera-bulko.org"
    end

    test "render recipe reference for sukera bulko", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/search?title=sukera")

      assert view
      |> element("td.recipe-reference-search")
      |> render() =~ "https://sukera-bulko.org"
      refute view
      |> element("td.recipe-reference-search")
      |> render() =~ "ia podkasto"
    end
  end
end
