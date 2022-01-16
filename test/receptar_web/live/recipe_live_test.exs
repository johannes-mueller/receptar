defmodule ReceptarWeb.RecipeLiveTest do
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Phoenix.LiveViewTest

  import Receptar.Seeder
  import Receptar.TestHelpers

  alias Receptar.Recipes
  alias Receptar.Substances
  alias Receptar.Units

  alias ReceptarWeb.RecipeLive

  defp create_socket() do
    %{socket: %Phoenix.LiveView.Socket{}}
  end

  describe "Socket state RecipeLiveTest" do
    setup do
      insert_test_data()
      create_socket()
    end

    test "initially edit_title flag false known recipe", %{socket: socket} do
	recipe_id = recipe_id("granda kino")

	{:ok, socket} =
	  RecipeLive.mount(%{"id" => recipe_id}, nil, socket)

	assert socket.assigns.edit_title == false
    end

    test "initially edit_title flag true unknown recipe", %{socket: socket} do
	{:ok, socket} =
	  RecipeLive.mount(%{}, nil, socket)

	assert socket.assigns.edit_title == true
    end

    test "edit-title event sets edit_title to true", %{socket: socket} do
	recipe_id = recipe_id("granda kino")

	{:ok, socket} =
	  RecipeLive.mount(%{"id" => recipe_id}, nil, socket)

	{:noreply, socket} =
	  RecipeLive.handle_event("edit-title", %{}, socket)

	assert socket.assigns.edit_title == true
    end


    for {language, title} <- [{"eo", "Grandega kino"}, {"de", "Epochales Theater"}] do
      test "submit-title (#{language})", %{socket: socket} do
	language = unquote(language)
	title = unquote(title)

	recipe_id = recipe_id("granda kino")

	{:ok, socket} =
	  RecipeLive.mount(%{"id" => recipe_id, "language" => language}, nil, socket)

	{:noreply, socket} =
	  RecipeLive.handle_event("submit-title", %{"title" => title}, socket)

	assert socket.assigns.recipe.title == title

	recipe = Recipes.get_recipe!(recipe_id)
	|> Recipes.translate(language)

	assert recipe.title == title
      end
    end

    test "submit-title sets edit_title to false", %{socket: socket} do
	recipe_id = recipe_id("granda kino")

	{:ok, socket} =
	  RecipeLive.mount(%{"id" => recipe_id, "language" => "eo"}, nil, socket)

	socket = %{socket | assigns: %{socket.assigns | edit_title: true}}

	{:noreply, socket} =
	  RecipeLive.handle_event("submit-title", %{"title" => "foo"}, socket)

	assert socket.assigns.edit_title == false
    end

    test "cancel-edit-title event sets edit_title to false", %{socket: socket} do
	recipe_id = recipe_id("granda kino")

      {:ok, socket} =
	  RecipeLive.mount(%{"id" => recipe_id, "language" => "eo"}, nil, socket)

	socket = %{socket | assigns: %{socket.assigns | edit_title: true}}

	{:noreply, socket} =
	  RecipeLive.handle_event("cancel-edit-title", %{}, socket)

	assert socket.assigns.edit_title == false
    end

    for {substance_name, unit_name, language} <- [
	  {"salo", "gramo", "eo"},
	  {"Salz", "Gramm", "de"}
	] do
	test "submit ingredient known (#{language}) substance", %{socket: socket} do
	  substance_name = unquote(substance_name)
	  unit_name = unquote(unit_name)
	  language = unquote(language)

	  expected_susbstance_id = Substances.get_by_translation(substance_name, language).id
	  expected_unit_id = Units.get_by_translation(unit_name, language).id

	  recipe_id = recipe_id("granda kino")

	  {:ok, socket} =
	    RecipeLive.mount(%{"id" => recipe_id, "language" => language}, nil, socket)

	  {:noreply, socket} =
	    RecipeLive.handle_info(
	      {
		:update_ingredients,
		%{
		  ingredients: [
		    %{
		      amount: Decimal.new("1"),
		      unit: %{name: unit_name},
		      substance: %{name: substance_name, kind: :vegan},
		      number: 1
		    }
		  ]
		}
	      },
	      socket
	    )

	  assert [%{
		     substance: %{id: ^expected_susbstance_id},
		     number: 1,
		  }] = socket.assigns.recipe.ingredients

	  assert %{ingredients:  [
		      %{
			substance: %{id: ^expected_susbstance_id},
			number: 1,
			unit: %{id: ^expected_unit_id}
		      }
		    ]
	  } = Recipes.get_recipe!(recipe_id) |> Recipes.translate("eo")
	end
    end

    for {language, content} <- [{"eo", "ĉion samtempe"}, {"de", "alles auf einmal"}] do
      test "update instructions #{language}", %{socket: socket} do
	language = unquote(language)
	content = unquote(content)

	recipe_id = recipe_id("granda kino")

	{:ok, socket} =
	  RecipeLive.mount(%{"id" => recipe_id, "language" => language}, nil, socket)

	{:noreply, socket} =
	  RecipeLive.handle_info(
	    {
	      :update_instructions,
	      %{
		instructions: [%{content: content, number: 1}],
		edit_instructions: []
	      }
	    },
	    socket
	  )

	assert [
	  %Receptar.Instructions.Instruction{
	    translations: [%{language: ^language, content: ^content}],
	    number: 1}
	] = socket.assigns.recipe.instructions

	assert [%{content: ^content}] = socket.assigns.recipe.instructions

	recipe = Recipes.get_recipe!(recipe_id) |> Recipes.translate(language)
	assert [%{content: ^content, number: 1}] = recipe.instructions
      end
    end
  end


  describe "Connection state" do
    setup %{conn: conn} do
      insert_test_data()
      register_and_log_in_user(%{conn: conn})
    end

    test "title does initially not have a form element", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      refute view
      |> element("h1 form")
      |> has_element?
    end

    test "title has a form element after edit-title event", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      html = view
      |> element("h1")
      |> render_click()

      assert html =~ ~r/<form phx-submit="submit-title"/
      assert html =~ ~r/<button.*phx-click="cancel-edit-title"/
      assert html =~ ~r/<button.*type="button"/
    end

    test "title edit form defaults to old title", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      html = view
      |> element("h1")
      |> render_click()

      assert html =~ ~r/<h1.*>.*<input.* value="Granda kino".*<\/h1>/
    end

    test "create new recipe title form empty", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/recipe/new")

      assert view
      |> element("h1 form")
      |> render() =~ ~r|value=""|
    end
  end

  describe "No authenticated user" do
    test "redirect", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = live(conn, "/recipe/23")
    end
  end
end
