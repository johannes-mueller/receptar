defmodule ReceptarWeb.IngredientLive do
  use ReceptarWeb, :live_component

  alias Receptar.Units
  alias Receptar.Substances.Substance

  alias ReceptarWeb.IngredientView
  alias ReceptarWeb.IngredientsLive

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(substance_suggestions: [])
     |> assign(unit_suggestions: Units.completion_candidates("", assigns.language))
     |> assign_field_values(assigns)
     #|> IO.inspect(label: "update_ingerdient_live")
    }
  end

  defp assign_field_values(socket, %{ingredient: ingredient}) do
    socket
    |> assign_amount_field_value(ingredient)
    |> assign(unit_name_value: ingredient.unit.name)
    |> assign(substance_name_value: ingredient.substance.name)
  end

  defp assign_field_values(socket, _attrs), do: socket

  defp assign_amount_field_value(socket, ingredient) do
    amount = ingredient.amount
    socket
    |> assign(amount_value: if amount do Decimal.to_string(amount, :xsd) else "" end)
  end

  def handle_event("make-suggestion", attrs, socket) do
    socket = case attrs do
	       %{"_target" => ["substance-name"]} ->
		 socket
		 |> make_substance_suggestion(attrs)
		 |> assign(substance_name_value: attrs["substance-name"])
	       %{"_target" => ["unit-name"]} ->
		 socket
		 |> make_unit_suggestion(attrs)
		 |> assign(unit_name_value: attrs["unit-name"])
	       %{"_target" => ["amount"]} ->
		 socket
		 |> assign(amount_value: attrs["amount"])
	       _ -> socket
	     end
    {:noreply, socket}
  end

  def handle_event("submit", attrs, socket) do
    amount = Decimal.new(attrs["amount"])

    substance_kind = case attrs["substance-kind"] do
		       "meat" -> :meat
		       "vegan" -> :vegan
		       "vegetarian" -> :vegetarian
		     end

    "ingredient-" <> number_string = attrs["number"]
    number = String.to_integer(number_string)

    ingredient = %{
      amount: amount,
      substance: %{
	name: attrs["substance-name"],
	kind: substance_kind
      },
      unit: %{name: attrs["unit-name"]},
      number: number
    }

    send_update(IngredientsLive, id: "ingredients", submit_ingredient: ingredient)

    {:noreply, socket}
  end

  defp make_substance_suggestion(socket, %{"substance-name" => prefix}) do
    %{assigns: %{language: language}} = socket
    suggestions = Receptar.Substances.completion_candidates(prefix, language)

    assign(socket, :substance_suggestions, suggestions)
  end

  defp make_unit_suggestion(socket, %{"unit-name" => prefix}) do
    %{assigns: %{language: language}} = socket
    suggestions = Receptar.Units.completion_candidates(prefix, language)

    assign(socket, :unit_suggestions, suggestions)
  end
end
