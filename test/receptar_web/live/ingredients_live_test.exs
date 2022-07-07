defmodule ReceptarWeb.IngerdientsLiveTest do
  import Assertions
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Phoenix.LiveViewTest
  import Phoenix.LiveView

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

      params = %{ingredients: ingredients, edit_ingredients: [], language: "eo"}
      {:ok, socket} = IngredientsLive.update(params, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_ingredients: []}
      } = socket
    end

    test "add ingredient to edit list", %{socket: socket} do
      ingredients =
      	recipe_by_title("granda kino").ingredients
	|> Ingredients.translate("eo")

      params = %{ingredients: ingredients, edit_ingredients: [], language: "eo"}
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

      params = %{ingredients: ingredients, edit_ingredients: [], language: "eo"}
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

      params = %{ingredients: ingredients, edit_ingredients: [], language: "eo"}
      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, _socket} =
	IngredientsLive.handle_event("edit-ingredient", %{"number" => "foo"}, socket)
    end

    for {recipe_name} <- [{"granda kino"}, {"sukera bulko"}] do
      test "append ingredient to event #{recipe_name}", %{socket: socket} do
	recipe = recipe_by_title(unquote(recipe_name))

	params = %{ingredients: recipe.ingredients, edit_ingredients: [], language: "eo"}
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
      params = %{ingredients: [], edit_ingredients: [], language: "eo"}

      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("append-ingredient", %{}, socket)

      {:ok, socket} =
	  IngredientsLive.update(%{cancel: 1}, socket)

      assert socket.assigns.ingredients == []
    end

    test "cancel after two appends", %{socket: socket} do
      params = %{ingredients: [], edit_ingredients: [], language: "eo"}

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

      params = %{ingredients: ingredients, edit_ingredients: [], language: "eo"}
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

      params = %{ingredients: ingredients, edit_ingredients: [], language: "eo"}
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

      params = %{ingredients: ingredients, edit_ingredients: [1], language: "eo"}
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

    test "submit substance add translation", %{socket: socket} do
      ingredients =
	recipe_by_title("granda kino").ingredients
        |> Ingredients.translate("eo")

      [%{substance: substance} | _] = ingredients

      translations_updated = [
	%{language: "sk", content: "cestovina"} | substance.translations
      ]

      {:ok, _socket} =
	IngredientsLive.update(
	  %{
	    update_translations: %{
	      translatable: substance,
	      translations: translations_updated
	    }
	  },
	  socket
	)

      assert_received(
	{
	  :update_translations,
	  %{
	    translatable: ^substance,
	    translations: ^translations_updated
	  }
	}
      )
    end

    for {number, amount} <- [{1, "42"}, {2, "23"}] do
      test "submit-amount-edit changes amount #{number}", %{socket: socket} do
	number = unquote(number)
	amount = unquote(amount)
	ingredients =
	  recipe_by_title("granda kino").ingredients
          |> Ingredients.translate("eo")

	params = %{ingredients: ingredients, language: "eo", edit_ingredients: []}
	{:ok, socket} = IngredientsLive.update(params, socket)

	{:noreply, socket} =
	  IngredientsLive.handle_event(
	    "submit-amount-edit",
	    %{"number" => "#{number}", "amount" => amount},
	    socket |> assign(edit_item: {number, :amount})
	  )

	ingredients = socket.assigns.ingredients
	ingredient = Enum.find(ingredients, & &1.number == number)

	assert ingredient.amount == Decimal.new(amount)
	assert socket.assigns.edit_item == nil

	assert_received({:update_ingredients, %{ingredients: ^ingredients}})
      end
    end

    test "cancel-edit-amount cancels", %{socket: socket} do
	ingredients =
	  recipe_by_title("granda kino").ingredients
          |> Ingredients.translate("eo")

	params = %{ingredients: ingredients, language: "eo", edit_ingredients: []}
	{:ok, socket} = IngredientsLive.update(params, socket)

	{:noreply, socket} =
	  IngredientsLive.handle_event(
	    "cancel-amount-edit-1", %{},
	    socket |> assign(edit_item: {1, :amount})
	  )

	assert socket.assigns.edit_item == nil
    end

    for {number, remianing} <- [{1, [2]}, {2, [1]}] do
      test "cancel ingredient #{number}", %{socket: socket} do
	ingredients = recipe_by_title("Tinusa bulko").ingredients
	|> Ingredients.translate("eo")

	params = %{ingredients: ingredients, edit_ingredients: [1, 2], language: "eo"}
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

	  params = %{ingredients: recipe.ingredients, edit_ingredients: [], language: "eo"}
	  {:ok, socket} = IngredientsLive.update(params, socket)

	  {:noreply, _socket} =
	    IngredientsLive.handle_event("delete-ingredient", %{"number" => number}, socket)

	  assert_received(
	    {
	      :update_ingredients,
	      %{
		ingredients: [
		  %{substance: %Substance{name: ^remaining_1}, number: 1},
		  %{substance: %Substance{name: ^remaining_2}, number: 2}
		]
	      }
	    }
	  )
	end
    end

    test "push ingredient number 1", %{socket: socket} do
      recipe = recipe_by_title("granda kino") |> Receptar.Recipes.translate("eo")

      params = %{ingredients: recipe.ingredients, edit_ingredients: [], language: "eo"}
      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, _socket} =
	IngredientsLive.handle_event("push-ingredient", %{"number" => "1"}, socket)

      assert_received(
	{
	  :update_ingredients,
	  %{
	    ingredients: [
	      %{substance: %Substance{name: "tinuso"}, number: 1},
	      %{substance: %Substance{name: "nudeloj"}, number: 2},
	      %{substance: %Substance{name: "salo"}, number: 3},
	    ]
	  }
	}
      )
    end

    test "pull ingredient number 3", %{socket: socket} do
      recipe = recipe_by_title("granda kino") |> Receptar.Recipes.translate("eo")

      params = %{ingredients: recipe.ingredients, edit_ingredients: [], language: "eo"}
      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, _socket} =
	IngredientsLive.handle_event("pull-ingredient", %{"number" => "3"}, socket)

      assert_received(
	{
	  :update_ingredients,
	  %{
	    ingredients: [
	      %{substance: %Substance{name: "nudeloj"}, number: 1},
	      %{substance: %Substance{name: "salo"}, number: 2},
	      %{substance: %Substance{name: "tinuso"}, number: 3},
	    ]
	  }
	}
      )
    end


    test "by default no substance and amount to be translated", %{socket: socket} do
      ingredients =
      	recipe_by_title("granda kino").ingredients
	|> Ingredients.translate("eo")

      params = %{ingredients: ingredients, edit_ingredients: [], language: "eo"}
      {:ok, socket} = IngredientsLive.update(params, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_item: nil}
      } = socket
    end

    for {number, number_string, item} <- [{1, "1", :substance}, {2, "2", :unit}] do
      test "edit_item set after edit-item #{number} event", %{socket: socket} do
	number = unquote(number)
	number_string = unquote(number_string)
	item = unquote(item)
	ingredients =
      	  recipe_by_title("granda kino").ingredients
	|> Ingredients.translate("eo")

	params = %{ingredients: ingredients, edit_ingredients: [], language: "eo"}
	{:ok, socket} = IngredientsLive.update(params, socket)

	attrs = %{"number" => number_string}
	event = "edit-" <> Atom.to_string(item)

	{:noreply, socket} =
	  IngredientsLive.handle_event(event, attrs, socket)

	assert %Phoenix.LiveView.Socket{
	  assigns: %{edit_item: {^number, ^item}}
	} = socket
      end
    end

    test "edit_item reset after translation-done", %{socket: socket} do
      ingredients =
      	recipe_by_title("granda kino").ingredients
      |> Ingredients.translate("eo")

      params = %{ingredients: ingredients, edit_ingredients: [], language: "eo"}
      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("edit-substance", %{"number" => "1"}, socket)

      [first_ingredient | _] = ingredients

      {:ok, socket} =
	IngredientsLive.update(
	  %{
	    update_translations: first_ingredient,
	    translations: %{}
	  },
	  socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_item: nil}
      } = socket
    end

    test "edit_item nil reset after cancel-translation one item", %{socket: socket} do
      ingredients =
      	recipe_by_title("granda kino").ingredients
      |> Ingredients.translate("eo")

      params = %{ingredients: ingredients, edit_ingredients: [], language: "eo"}
      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("edit-substance", %{"number" => "1"}, socket)

      [first_ingredient | _] = ingredients

      {:ok, socket} =
	IngredientsLive.update(
	  %{
	    cancel_translation: first_ingredient
	  },
	  socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_item: nil}
      } = socket

    end

    @tag :skip #multiple ingredient translation not implemented yet
    test "edit_item reset after cancel-translation two items", %{socket: socket} do
      ingredients =
      	recipe_by_title("granda kino").ingredients
      |> Ingredients.translate("eo")

      params = %{ingredients: ingredients, edit_ingredients: [], language: "eo"}
      {:ok, socket} = IngredientsLive.update(params, socket)

      {:noreply, socket} =
	IngredientsLive.handle_event("edit-substance", %{"number" => "1"}, socket)
      {:noreply, socket} =
	IngredientsLive.handle_event("edit-substance", %{"number" => "2"}, socket)

      [first_ingredient | _tail] = ingredients
      #[second_ingredient | _] = tail

      {:ok, socket} =
	IngredientsLive.update(
	  %{
	    cancel_translation: first_ingredient
	  },
	  socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_item: [2]}
      } = socket

    end
  end

  describe "Connection state" do
    setup do
      insert_test_data()
      %{ingredient: %{
	   substance: %Substance{
	     id: 2342,
	     translations: [
	       %{language: "eo", content: "salo"},
	       %{language: "de", content: "Salz"}
	     ]
	   },
	   amount: Decimal.new("23.0"),
	   unit: %{name: "gramo", translations: [%{language: "eo", content: "gramo"}]},
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

    for number <- [1, 2] do
	@tag :skip  # will be done differently
	test "test edit ingredient #{number} click", %{conn: conn, ingredient: ingredient} do
	  number = unquote(number)
	  selector = "#ingredient-#{number}"

	  session = %{"ingredients" => [
		       %{ingredient | number: 1},
		       %{ingredient | number: 2},
		     ]}
	  {:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	  view
	  |> element(selector)
	  |> render_click()

	  #assert view |> has_element?("form#edit-ingredient-" <> number)
	end
    end

    for number <- [1, 2] do
      test "test translate substance #{number} click", %{conn: conn, ingredient: ingredient} do
	number = unquote(number)
	session = %{"ingredients" => [
		     %{ingredient | number: 1},
		     %{ingredient | number: 2},
		   ]}
	{:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	refute view |> has_element?("form#edit-translation-translations-substance-#{number}")

	view
	|> element("#ingredient-substance-#{number}")
	|> render_click()

	assert view |> has_element?("form#edit-translation-translations-substance-#{number}")
      end

      test "test translate unit #{number} click", %{conn: conn, ingredient: ingredient} do
	number = unquote(number)
	session = %{"ingredients" => [
		     %{ingredient | number: 1},
		     %{ingredient | number: 2},
		   ]}
	{:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	refute view |> has_element?("form#edit-translation-translations-unit-#{number}")

	view
	|> element("#ingredient-unit-#{number}")
	|> render_click()

	assert view |> has_element?("form#edit-translation-translations-unit-#{number}")
      end

      test "test edit amount #{number} click creates form", %{conn: conn, ingredient: ingredient} do
	number = unquote(number)
	session = %{"ingredients" => [
		     %{ingredient | number: 1},
		     %{ingredient | number: 2, amount: Decimal.new("4.2")},
		   ]}
	{:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	refute view |> has_element?("form#edit-amount-#{number}")

	view
	|> element("#ingredient-amount-#{number}")
	|> render_click()

	assert view |> has_element?("form#edit-amount-#{number}")
      end

      test "test edit amount #{number} input has default", %{conn: conn, ingredient: ingredient} do
	number = unquote(number)
	expected_numbers = %{1 => "23.0", 2 => "4.2"}

	session = %{"ingredients" => [
		     %{ingredient | number: 1},
		     %{ingredient | number: 2, amount: Decimal.new("4.2")},
		   ]}
	{:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	refute view |> has_element?("form#edit-amount-#{number}")

	view
	|> element("#ingredient-amount-#{number}")
	|> render_click()

	selector = "input[name=\"amount\"][type=\"number\"][step=\"0.1\"][value=\"#{expected_numbers[number]}\"]"
	assert view |> has_element?("form#edit-amount-#{number} " <> selector)
      end
    end

    test "submit edit amount click does not fail", %{conn: conn, ingredient: ingredient} do
	session = %{"ingredients" => [ingredient]}
	{:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	view
	|> element("#ingredient-amount-1")
	|> render_click()

	view
	|> element("form#edit-amount-1")
	|> render_submit()
    end

    test "cancel edit amount click does not fail", %{conn: conn, ingredient: ingredient} do
	session = %{"ingredients" => [ingredient]}
	{:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	view
	|> element("#ingredient-amount-1")
	|> render_click()

	view
	|> element("form#edit-amount-1 button.cancel")
	|> render_click()
    end


    test "append ingredient", %{conn: conn} do
      session = %{"ingredients" => []}
      {:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

      refute view |> has_element?("form[phx-submit=\"submit\"]")

      button_click = "[phx-click=\"append-ingredient\"]"

      view
      |> element("button.add-button" <> button_click)
      |> render_click()

      assert view |> has_element?("form[phx-submit=\"submit\"]")
    end

    for number <- [1, 2] do
      test "ingredient #{number} has delete button", %{conn: conn, ingredient: ingredient} do
	number = unquote(number)
	session = %{
	  "ingredients" => [%{ingredient | number: number}],
	  "edit_ingredients" => []
	}
	{:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	button_click = "[phx-click=\"delete-ingredient\"]"
	button_value = "[phx-value-number=\"#{number}\"]"

	view
	|> element("button.delete-button" <> button_click <> button_value)
	|> render_click()
      end

      test "ingredient #{number} has insert button", %{conn: conn, ingredient: ingredient} do
	number = unquote(number)
	session = %{
	  "ingredients" => [%{ingredient | number: number}],
	  "edit_ingredients" => []
	}
	{:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	button_click = "[phx-click=\"insert-ingredient\"]"
	button_value = "[phx-value-number=\"#{number}\"]"

	view
	|> element("button.add-button" <> button_click <> button_value)
	|> render_click()
      end

      test "ingredient #{number} has push button", %{conn: conn, ingredient: ingredient} do
	number = unquote(number)
	session = %{
	  "ingredients" => [%{ingredient | number: number}],
	  "edit_ingredients" => []
	}
	{:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	button_click = "[phx-click=\"push-ingredient\"]"
	button_value = "[phx-value-number=\"#{number}\"]"

	view
	|> element("button.down-button" <> button_click <> button_value)
	|> render_click()
      end

      test "ingredient #{number} has pull button", %{conn: conn, ingredient: ingredient} do
	number = unquote(number)
	session = %{
	  "ingredients" => [%{ingredient | number: number}],
	  "edit_ingredients" => []
	}
	{:ok, view, _html} = live_isolated(conn, IngredientsTestLiveView, session: session)

	button_click = "[phx-click=\"pull-ingredient\"]"
	button_value = "[phx-value-number=\"#{number}\"]"

	view
	|> element("button.up-button" <> button_click <> button_value)
	|> render_click()
      end

    end
  end
end


defmodule ReceptarWeb.IngredientsTestLiveView do
  use Phoenix.LiveView

  alias ReceptarWeb.IngredientsLive

  def render(assigns) do
    ~H"<.live_component
    module={IngredientsLive}
    id=\"ingredients\"
    ingredients={@ingredients}
    edit_ingredients={@edit_ingredients}
    language=\"eo\"
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
    }
  end
end
