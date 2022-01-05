defmodule ReceptarWeb.IngredientsLive do
  use ReceptarWeb, :live_component

  alias Receptar.Orderables
  alias Receptar.Substances.Substance

  alias ReceptarWeb.Helpers

  alias ReceptarWeb.IngredientLive

  def update(%{submit_ingredient: ingredient}, socket) do
    ingredients = socket.assigns.ingredients

    ingredients = Orderables.replace(ingredients, ingredient)

    edit_ingredients =
      socket.assigns.edit_ingredients
      |> Enum.filter(& &1 != ingredient.number)

    send self(), {
      :update_ingredients,
      %{
	ingredients: ingredients,
      }
    }

    {:ok,
     socket
     |> assign(edit_ingredients: edit_ingredients)
     |> assign(ingredients: ingredients)
    }
  end

  def update(params, socket) do
    socket = socket
    |> assign(language: Helpers.determine_language(params))
    |> assign(ingredients: params.ingredients)
    |> assign(edit_ingredients: params.edit_ingredients)

    {:ok, socket}
  end

  def handle_event("edit-ingredient", %{"number" => number}, socket) do
    edit_list = maybe_add_to_list(number, socket.assigns.edit_ingredients)
    {:noreply, socket |> assign(edit_ingredients: edit_list)}
  end

  def handle_event("append-ingredient", _attrs, socket) do
    ingredients = socket.assigns.ingredients

    {new_number, new_ingredients} =
      ingredients
      |> Orderables.append(
        %{amount: nil, unit: %{name: ""}, substance: %Substance{name: ""}}
      )

    {:noreply,
     socket
     |> assign(ingredients: new_ingredients)
     |> assign(edit_ingredients: [new_number])
    }
  end

  def handle_event("delete-ingredient", %{"number" => number}, socket) do
    number = String.to_integer(number)

    ingredients = Orderables.delete(socket.assigns.ingredients, %{number: number})

    send self(), {
      :update_ingredients,
      %{ingredients: ingredients}
    }

    {:noreply, socket}
  end

  defp maybe_add_to_list(number, list) do
    case Integer.parse(number) do
      :error -> list
      {i, _remainder} ->
	if i not in list do
	  [i | list]
	else
	  list
	end
    end
  end

end
