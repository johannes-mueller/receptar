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

  describe "Socket state RecipeLiveTest" do
    setup do
      insert_test_data()

      recipe_id = recipe_id("granda kino")
      {:ok, socket} =
	RecipeLive.mount(
	  %{"id" => recipe_id}, %{"language" => "eo"},
	  %Phoenix.LiveView.Socket{}
	)

      %{socket: socket}
    end

    test "initially edit_title flag false known recipe", %{socket: socket} do
      assert socket.assigns.edit_title == false
    end

    test "initially edit_servings flag false known recipe", %{socket: socket} do
      assert socket.assigns.edit_servings == false
    end

    test "edit-title event sets edit_title to true", %{socket: socket} do
      {:noreply, socket} =
	RecipeLive.handle_event("edit-title", %{}, socket)

      assert socket.assigns.edit_title == true
    end

    for {language, title} <- [
	  {"eo", "Grandega kino"},
	  {"de", "Epochales Theater"},
	  {"sk", "veľké kino"}
	] do
      test "update-translation of title in (#{language})", %{socket: socket} do
	language = unquote(language)
	title = unquote(title)

	recipe = recipe_by_title("granda kino")

	{:ok, socket} =
	  RecipeLive.mount(%{"id" => recipe.id}, %{"language" => language}, socket)

	translations_updated = [%{language: language, content: title}]

	{:noreply, socket} =
	  RecipeLive.handle_info(
	    {
	      :update_translations,
	      %{translatable: recipe, translations: translations_updated}
	    },
	    socket
	  )

	assert socket.assigns.recipe.title == title

	recipe = Recipes.get_recipe!(recipe.id)
	|> Recipes.translate(language)

	assert recipe.title == title
      end
    end

    test "cancel-translation resets edit_title", %{socket: socket} do
      recipe = recipe_by_title("granda kino")

      {:noreply, socket} =
	RecipeLive.handle_event("edit-title", %{}, socket)

      {:noreply, socket} = RecipeLive.handle_info({:cancel_translation, recipe}, socket)

      assert socket.assigns.edit_title == false
    end

    test "update-translation of title sets edit_title to false", %{socket: socket} do
	recipe = recipe_by_title("granda kino")

	socket = %{socket | assigns: %{socket.assigns | edit_title: true}}

	{:noreply, socket} =
	  RecipeLive.handle_info(
	    {
	      :update_translations,
	      %{translatable: recipe, translations: [%{language: "eo", content: "uuuu"}]}
	    },
	    socket
	  )

	assert socket.assigns.edit_title == false
    end

    test "cancel-translation of description sets edit_description to false", %{socket: socket} do
	recipe = recipe_by_title("granda kino")

	socket = %{socket | assigns: %{socket.assigns | edit_description: true}}

	{:noreply, socket} = RecipeLive.handle_info({:cancel_translation, recipe.recipe_description}, socket)

	assert socket.assigns.edit_description == false
    end

    test "update-translation of description sets edit_description to false", %{socket: socket} do
	recipe = recipe_by_title("granda kino")

	socket = %{socket | assigns: %{socket.assigns | edit_description: true}}

	{:noreply, socket} =
	  RecipeLive.handle_info(
	    {
	      :update_translations,
	      %{translatable: recipe.recipe_description, translations: [%{language: "eo", content: "uuuu"}]}
	    },
	    socket
	  )

	assert socket.assigns.edit_description == false
    end

    test "initally edit_description is false", %{socket: socket} do
      assert socket.assigns.edit_description == false
    end

    test "edit-servings event sets edit_servings flag", %{socket: socket} do
      {:noreply, socket} = RecipeLive.handle_event("edit-servings", %{}, socket)
      assert socket.assigns.edit_servings == true
    end

    test "submit-edit-servings resets edit_servings flag", %{socket: socket} do
      socket = %{socket | assigns: %{socket.assigns | edit_servings: true}}
      {:noreply, socket} = RecipeLive.handle_event("submit-servings", %{"servings" => "3"}, socket)
      assert socket.assigns.edit_servings == false
    end

    for servings <- [3, 4] do
      test "submit-edit-servings updates recipe to #{servings} servings", %{socket: socket} do
	servings = unquote(servings)
	recipe_id = socket.assigns.recipe.id

	socket = %{socket | assigns: %{socket.assigns | edit_servings: true}}
	{:noreply, socket} = RecipeLive.handle_event("submit-servings", %{"servings" => "#{servings}"}, socket)

	assert socket.assigns.recipe.servings == servings
	assert Receptar.Recipes.get_recipe!(recipe_id).servings == servings
      end
    end

    test "submit-edit-servings non integer input does not fail", %{socket: socket} do
      socket = %{socket | assigns: %{socket.assigns | edit_servings: true}}
      {:noreply, socket} = RecipeLive.handle_event("submit-servings", %{"servings" => "uuuh"}, socket)
      assert socket.assigns.recipe.servings == 2
    end

    test "cancel-edit-servings event resets edit_servings flag", %{socket: socket} do
      socket = %{socket | assigns: %{socket.assigns | edit_servings: true}}
      {:noreply, socket} = RecipeLive.handle_event("cancel-edit-servings", %{}, socket)
      assert socket.assigns.edit_servings == false
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
	    RecipeLive.mount(%{"id" => recipe_id}, %{"language" => language}, socket)

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

	  assert [
	    %{
	      unit: %{name: ^unit_name},
	      substance: %{name: ^substance_name}
	    }
	  ] = socket.assigns.recipe.ingredients

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
	  } = Recipes.get_recipe!(recipe_id)
	end
    end

    for {language, content} <- [{"eo", "ĉion samtempe"}, {"de", "alles auf einmal"}] do
      test "update instructions #{language}", %{socket: socket} do
	language = unquote(language)
	content = unquote(content)

	recipe_id = recipe_id("granda kino")

	{:ok, socket} =
	  RecipeLive.mount(%{"id" => recipe_id}, %{"language" => language}, socket)

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

    test "add translation substance", %{socket: socket} do
      recipe_id = recipe_id("granda kino")

      {:ok, socket} =
	RecipeLive.mount(%{"id" => recipe_id}, %{"language" => "eo"}, socket)

      %{
	recipe: %{
	  ingredients: [%{substance: substance} | _]
	}
      } = socket.assigns

      translations_updated = [
	%{language: "sk", content: "cestovina"} | substance.translations
      ]

      {:noreply, socket} =
	RecipeLive.handle_info(
	  {
	    :update_translations,
	    %{translatable: substance, translations: translations_updated}
	  },
	  socket
	)

      new_substance = Substances.get_by_translation("cestovina", "sk")
      assert new_substance.id == substance.id

      %{
	recipe: %{
	  ingredients: [%{substance: substance} | _]
	}
      } = socket.assigns

      assert substance.translations
      |> Enum.any?(fn
	%{language: "sk", content: "cestovina"} -> true
	_ -> false
      end)
    end

    test "change translation substance", %{socket: socket} do
      recipe_id = recipe_id("granda kino")

      {:ok, socket} =
	RecipeLive.mount(%{"id" => recipe_id}, %{"language" => "eo"}, socket)

      %{
	recipe: %{
	  ingredients: [%{substance: substance} | _]
	}
      } = socket.assigns

      translations_updated =
	substance.translations
	|> Enum.map(fn
	%{language: "eo"} = tr -> %{tr | content: "nuuudeloj"}
	tr -> tr
        end)


      {:noreply, socket} =
	RecipeLive.handle_info(
	  {:update_translations,
	   %{
	     translatable: substance,
	     translations: translations_updated
	   }
	  }, socket)

      new_substance = Substances.get_by_translation("nuuudeloj", "eo")
      assert new_substance.id == substance.id

      refute Substances.get_by_translation("nudeloj", "eo")

      %{
	recipe: %{
	  ingredients: [%{substance: substance} | _]
	}
      } = socket.assigns

      assert substance.translations
      |> Enum.any?(fn
	%{language: "eo", content: "nuuudeloj"} -> true
	_ -> false
      end)

      refute substance.translations
      |> Enum.any?(fn
	%{language: "eo", content: "nudeloj"} -> true
	_ -> false
      end)
    end
  end

  describe "Connection state" do
    setup %{conn: conn} do
      insert_test_data()
      register_and_log_in_user(%{conn: conn})
    end

    test "page does initially not have a form element", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      refute view |> has_element?("form")
    end

    test "h1 title is shown in Esperanto", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      assert view |> element("h1") |> render() =~ ~r/Granda kino/
    end

    test "h1 title is translation missing in slovak", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}?language=sk")

      assert view |> element("h1") |> render() =~ ~r/Translation missing/
    end

    test "h1 title is shown in German", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}?language=de")

      assert view |> element("h1") |> render() =~ ~r/Großes Kino/
    end

    test "p description is shown in Esperanto", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      assert view
      |> element("p.recipe-description")
      |> render() =~ ~r/Vere granda kino/
    end

    test "p description is shown in German", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}?language=de")

      assert view
      |> element("p.recipe-description")
      |> render() =~ ~r/Echt ganz großes Kino/
    end

    test "description is translation missing in slovak", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}?language=sk")

      refute view |> has_element?("p.no-recipe-description")
      refute view |> has_element?("button.add-button[phx-click=\"edit-description\"]")

      assert view
      |> element("p.recipe-description")
      |> render() =~ ~r/Translation missing/
      assert view |> has_element?("button.edit-button[phx-click=\"edit-description\"]")
    end

    test "no description is shown for recipe without description", %{conn: conn} do
      id = recipe_id("Sardela pico")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      refute view |> has_element?("p.recipe-description")
      refute view |> has_element?("button.edit-button[phx-click=\"edit-description\"]")
      assert view |> has_element?("p.no-recipe-description")
      assert view |> has_element?("button.add-button[phx-click=\"edit-description\"]")
    end

    test "add-button for description click makes edit-description form appear", %{conn: conn} do
      id = recipe_id("Sardela pico")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      refute view |> has_element?("form[phx-submit=submit-description]")

      view
      |> element("button.add-button[phx-click=\"edit-description\"]")
      |> render_click()

      assert view |> has_element?("form[phx-submit=submit-description]")
      refute view |> has_element?("button.add-button[phx-click=\"edit-description\"]")
    end

    test "submit description makes description appear", %{conn: conn} do
      id = recipe_id("Sardela pico")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      view
      |> element("button.add-button[phx-click=\"edit-description\"]")
      |> render_click()

      view
      |> element("form[phx-submit=submit-description]")
      |> render_submit(%{description: "Vere estas sardela pico"})

      refute view |> has_element?("form[phx-submit=submit-description]")
      assert view
      |> element("p.recipe-description")
      |> render() =~ ~r/Vere estas sardela pico/

      recipe = Recipes.get_recipe!(id) |> Recipes.translate("eo")
      assert recipe.description == "Vere estas sardela pico"
    end

    test "cancel description makes description form disappear", %{conn: conn} do
      id = recipe_id("Sardela pico")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      view
      |> element("button.add-button[phx-click=\"edit-description\"]")
      |> render_click()

      view
      |> element("button[phx-click=\"cancel-edit-description\"]")
      |> render_click()

      refute view |> has_element?("form[phx-submit=submit-description]")
    end

    test "edit-button for description click makes translation edit form appear", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      refute view |> has_element?("form[phx-submit=submit-description]")

      view
      |> element("button.edit-button[phx-click=\"edit-description\"]")
      |> render_click()

      refute view |> has_element?("form[phx-submit=submit-description]")
      refute view |> has_element?("button.edit-button[phx-click=\"edit-description\"]")

      view
      |> element("form#edit-translation-recipe-description-#{id}")
      |> render_submit()  # no assertion possible as processing leaves the process
    end

    test "title has a form element after edit-title event", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      html = view
      |> element("h1")
      |> render_click()

      assert html =~ ~r/<form phx-submit="submit"/
      assert html =~ ~r/<button.*phx-click="cancel/
      assert html =~ ~r/<button.*type="button"/
    end

    test "title edit form defaults to old title", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      html = view
      |> element("h1")
      |> render_click()

      assert html =~ ~r/<input.* value="Granda kino"/
    end

    @tag :skip  # must be handled in SingleTranslationLive
    test "create recipe title form submit button is disabled", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      view
      |> element("h1")
      |> render_click()

      html = view
      |> element("h1 form")
      |> render()

      assert html =~ ~r/<button[^>]* type="submit"[^>]*disabled.*>/
    end

    @tag :skip  # must be handled in SingleTranslationLive
    test "create recipe title form submit button is enabled after input", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      view
      |> element("h1")
      |> render_click()

      html = view
      |> element("h1 form")
      |> render_change(title: "foo")

      refute html =~ ~r/<button[^>]* type="submit"[^>]*disabled.*>/
    end

    test "click on edit-servings-button makes edit-servings-form appear", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      refute view |> has_element?("form[phx-submit=\"submit-servings\"]")

      view
      |> element("button#edit-servings-button")
      |> render_click()

      assert view |> has_element?("form[phx-submit=\"submit-servings\"]")
    end

    test "submit edit-servings-form succeeds", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      view
      |> element("button#edit-servings-button")
      |> render_click()

      view
      |> element("form[phx-submit=\"submit-servings\"]")
      |> render_submit()
    end

    test "cancel edit-servings-form succeeds", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")

      view
      |> element("button#edit-servings-button")
      |> render_click()

      view
      |> element("button.cancel")
      |> render_click()
    end

    for {servings, recipe} <- [{2, "granda kino"}, {1, "sardela pico"}] do
      test "servings input for #{recipe} defaults to %{servings}", %{conn: conn} do
	id = recipe_id(unquote(recipe))
	{:ok, view, _html} = live(conn, "/recipe/#{id}")

	view
	|> element("button#edit-servings-button")
	|> render_click()

	assert view
	|> element("form input")
	|> render() =~ ~r/value="#{unquote(servings)}"/
      end
    end

  end

  describe "No authenticated user" do
    test "redirect", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = live(conn, "/recipe/23")
    end
  end
end
