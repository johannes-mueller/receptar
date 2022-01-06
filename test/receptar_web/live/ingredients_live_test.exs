defmodule ReceptarWeb.IngerdientsLiveTest do
  import Assertions
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Phoenix.LiveViewTest

  import Receptar.Seeder
  import Receptar.TestHelpers

  alias Receptar.Ingredients
  alias Receptar.Substances.Substance

  alias ReceptarWeb.IngredientsLive
  alias ReceptarWeb.IngredientsTestLiveView

  defp create_socket() do
    %{socket: %Phoenix.LiveView.Socket{}}
  end

  describe "Socket state" do
    setup do
      insert_test_data()
      create_socket()
    end

    test "by default no ingredients to be edited", %{socket: socket} do
      ingredients =
      	recipe_by_title("granda kino").ingredients
	|> Ingredients.translate("eo")

      params = %{ingredients: ingredients, edit_ingredients: []}
      {:ok, socket} = IngredientsLive.update(params, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_ingredients: []}
      } = socket
    end

    test "add ingredient to edit list", %{socket: socket} do
      ingredients =
      	recipe_by_title("granda kino").ingredients
	|> Ingredients.translate("eo")

      params = %{ingredients: ingredients, edit_ingredients: []}
      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("edit-ingredient", %{"number" => "1"}, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_ingredients: [1]}
      } = socket

      {:noreply, socket} =
	IngredientsLive.handle_event("edit-ingredient", %{"number" => "2"}, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_ingredients: [2, 1]}
      } = socket
    end

    test "add the same to edit list adds only once", %{socket: socket} do
      ingredients =
      	recipe_by_title("granda kino").ingredients
	|> Ingredients.translate("eo")

      params = %{ingredients: ingredients, edit_ingredients: []}
      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("edit-ingredient", %{"number" => "1"}, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("edit-ingredient", %{"number" => "1"}, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_ingredients: [1]}
      } = socket
    end

    test "add non int number to edit list does not fail", %{socket: socket} do
      ingredients =
      	recipe_by_title("granda kino").ingredients
	|> Ingredients.translate("eo")

      params = %{ingredients: ingredients, edit_ingredients: []}
      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, _socket} =
	IngredientsLive.handle_event("edit-ingredient", %{"number" => "foo"}, socket)
    end

    for {recipe_name} <- [{"granda kino"}, {"sukera bulko"}] do
      test "append ingredient to event #{recipe_name}", %{socket: socket} do
	recipe = recipe_by_title(unquote(recipe_name))

	params = %{ingredients: recipe.ingredients, edit_ingredients: []}
	{:ok, socket} = IngredientsLive.update(params, socket)

	original_ingredients = Ingredients.translate(recipe.ingredients, "eo")
	expected_ingredient_number = length(original_ingredients) + 1

	{:noreply, socket} =
	  IngredientsLive.handle_event("append-ingredient", %{}, socket)

	%{assigns: %{ingredients: ingredients}} = socket

	assert [
	  %{
	    number: ^expected_ingredient_number,
	    amount: nil,
	    unit: %{name: ""},
	    substance: %{name: ""}
	  } | tail] = Enum.reverse(ingredients)

	assert_lists_equal Enum.map(tail, & &1.id), Enum.map(original_ingredients, & &1.id)

	ingredients = Enum.sort(ingredients, & &1.number < &2.number)

	assert socket.assigns.ingredients == ingredients

	assert %Phoenix.LiveView.Socket{
	  assigns: %{edit_ingredients: [^expected_ingredient_number]}
	} = socket
      end
    end

    test "cancel after append", %{socket: socket} do
      params = %{ingredients: [], edit_ingredients: []}

      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("append-ingredient", %{}, socket)

      {:ok, socket} =
	  IngredientsLive.update(%{cancel: 1}, socket)

      assert socket.assigns.ingredients == []
    end

    test "cancel after two appends", %{socket: socket} do
      params = %{ingredients: [], edit_ingredients: []}

      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("append-ingredient", %{}, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("append-ingredient", %{}, socket)

      {:ok, socket} =
	  IngredientsLive.update(%{cancel: 2}, socket)

      assert [%{number: 1}] = socket.assigns.ingredients

      {:ok, socket} =
	  IngredientsLive.update(%{cancel: 1}, socket)

      assert socket.assigns.ingredients == []
    end

    test "insert ingredient 2", %{socket: socket} do
      ingredients =
	recipe_by_title("granda kino").ingredients
        |> Ingredients.translate("eo")

      params = %{ingredients: ingredients, edit_ingredients: []}
      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("insert-ingredient", %{"number" => "2"}, socket)

      assert [
	%{substance: %{name: "nudeloj"}, number: 1},
	%{substance: %{name: ""}, number: 2},
	%{substance: %{name: "tinuso"}, number: 3},
	%{substance: %{name: "salo"}, number: 4}
      ] = socket.assigns.ingredients

      assert socket.assigns.edit_ingredients == [2]
      assert socket.assigns.new_ingredients == [2]
    end

    test "insert ingredient 1 and 2", %{socket: socket} do
      ingredients =
	recipe_by_title("granda kino").ingredients
        |> Ingredients.translate("eo")

      params = %{ingredients: ingredients, edit_ingredients: []}
      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("insert-ingredient", %{"number" => "2"}, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("insert-ingredient", %{"number" => "1"}, socket)

      assert [
	%{substance: %{name: ""}, number: 1},
	%{substance: %{name: "nudeloj"}, number: 2},
	%{substance: %{name: ""}, number: 3},
	%{substance: %{name: "tinuso"}, number: 4},
	%{substance: %{name: "salo"}, number: 5}
      ] = socket.assigns.ingredients

      assert socket.assigns.edit_ingredients == [1, 3]
      assert socket.assigns.new_ingredients == [1, 3]
    end

    test "submit ingredient", %{socket: socket} do
      ingredients = recipe_by_title("Tinusa bulko").ingredients
      |> Ingredients.translate("eo")

      params = %{ingredients: ingredients, edit_ingredients: [1]}
      {:ok, socket} = IngredientsLive.update(params, socket)

      new_ingredient = %{
	amount:  Decimal.new("1"),
	unit: %{name: "kilogramo"},
	substance: %Substance{name: "ŝafa fromaĝo", kind: :vegetarian},
	number: 1
      }

      {:ok, socket} =
	IngredientsLive.update(%{submit_ingredient: new_ingredient}, socket)

      assert_received({
	:update_ingredients,
	%{
	  ingredients: [
	    %{substance: %Substance{name: "ŝafa fromaĝo", kind: :vegetarian}, number: 1},
	    %{substance: %Substance{name: "tinuso"}, number: 2}
	  ],
	}
      })

      assert socket.assigns.edit_ingredients == []
      assert [
	    %{substance: %Substance{name: "ŝafa fromaĝo", kind: :vegetarian}, number: 1},
	    %{substance: %Substance{name: "tinuso"}, number: 2}
      ] = socket.assigns.ingredients
    end

    for {number, remianing} <- [{1, [2]}, {2, [1]}] do
      test "cancel ingredient #{number}", %{socket: socket} do
	ingredients = recipe_by_title("Tinusa bulko").ingredients
	|> Ingredients.translate("eo")

	params = %{ingredients: ingredients, edit_ingredients: [1, 2]}
	{:ok, socket} = IngredientsLive.update(params, socket)

	{:ok, socket} =
	  IngredientsLive.update(%{cancel: unquote(number)}, socket)

	assert socket.assigns.edit_ingredients == unquote(remianing)
      end
    end

    for {number, remaining} <- [
	  {"1", ["tinuso", "salo"]},
	  {"2", ["nudeloj", "salo"]}
	] do
	test "delete ingredient #{number}", %{socket: socket} do
	  number = unquote(number)
	  [remaining_1, remaining_2] = unquote(remaining)

	  recipe = recipe_by_title("granda kino") |> Receptar.Recipes.translate("eo")

	  params = %{ingredients: recipe.ingredients, edit_ingredients: []}
	  {:ok, socket} = IngredientsLive.update(params, socket)

	  {:noreply, _socket} =
	    IngredientsLive.handle_event("delete-ingredient", %{"number" => number}, socket)

	  assert_received({
	    :update_ingredients,
	    %{
	      ingredients: [
		%{substance: %Substance{name: ^remaining_1}, number: 1},
		%{substance: %Substance{name: ^remaining_2}, number: 2}
	      ]
	    }
	  })
	end
    end
  end

  describe "Connection state" do
    setup do
      insert_test_data()
      %{ingredient: %{
	   substance: %Substance{name: "foo"},
	   amount: Decimal.new("23.0"),
	   unit: %{name: "gramo"},
	   number: 1
	}
      }
    end

    test "initial view does not have form elements",
      %{conn: conn, ingredient: ingredient} do

      session = %{"ingredients" => [ingredient]}
      {:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

      refute view |> has_element?("form")
    end


    for {number, selector} <- [
	  {"1", "#ingredient-1"},
	  {"2", "#ingredient-2"}
	] do
	test "edit ingredient #{number}", %{conn: conn, ingredient: ingredient} do
	  number = unquote(number)
	  selector = unquote(selector)

	  session = %{"ingredients" => [
		       %{ingredient | number: 1},
		       %{ingredient | number: 2},
		     ]}
	  {:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	  html = view
	  |> element(selector)
	  |> render()

	  assert html =~ ~r/phx-click="edit-ingredient"/
	  assert html =~ ~r/phx-value-number="#{number}"/
	end
    end

    test "test edit ingredient click", %{conn: conn, ingredient: ingredient} do
	  session = %{"ingredients" => [
		       %{ingredient | number: 1},
		       %{ingredient | number: 2},
		     ]}
	  {:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	  view
	  |> element("#ingredient-1")
	  |> render_click()
    end

    test "append ingredient", %{conn: conn} do
      session = %{"ingredients" => []}
      {:ok, view, html} = live_isolated(conn, IngredientsTestLiveView, session: session)

      refute html =~ ~r/<form.*phx-submit="submit"/

      html = view
      |> element("a#append-ingredient")
      |> render_click()
      |> strip_html_code

      assert html =~ ~r/<form.*phx-submit="submit"/
    end

    for number <- [1, 2] do
      test "ingredient #{number} has delete button", %{conn: conn, ingredient: ingredient} do
	number = unquote(number)
	session = %{
	  "ingredients" => [%{ingredient | number: number}],
	  "edit_ingredients" => []
	}
	{:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	delete_element = view
	|> element("a#delete-ingredient-#{number}")

	render_click(delete_element)

	html = delete_element
	|> render()

	assert html =~ ~r/phx-click="delete-ingredient"/
	assert html =~ ~r/phx-value-number="#{number}"/
      end

      test "ingredient #{number} has insert button", %{conn: conn, ingredient: ingredient} do
	number = unquote(number)
	session = %{
	  "ingredients" => [%{ingredient | number: number}],
	  "edit_ingredients" => []
	}
	{:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	insert_element = view
	|> element("a#insert-ingredient-#{number}")

	render_click(insert_element)

	html = insert_element
	|> render()

	assert html =~ ~r/phx-click="insert-ingredient"/
	assert html =~ ~r/phx-value-number="#{number}"/
      end
    end
  end
end


defmodule ReceptarWeb.IngredientsTestLiveView do
  use Phoenix.LiveView

  alias ReceptarWeb.IngredientsLive

  def render(assigns) do
    #IO.inspect(assigns, label: "render")
    ~H"<.live_component
    module={IngredientsLive}
    id=\"ingredients\"
    ingredients={@ingredients}
    edit_ingredients={@edit_ingredients}
    />"
  end

  def mount(_parmas, session, socket) do
    %{"ingredients" => ingredients} = session
    edit_ingredients = case session do
			  %{"edit_ingredients" => eis} -> eis
			  _ -> []
			end

    {:ok,
     socket
     |> assign(ingredients: ingredients)
     |> assign(edit_ingredients: edit_ingredients)
     #|> IO.inspect(label: "mount")
    }
  end
end
