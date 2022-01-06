defmodule ReceptarWeb.IngredientLive do
  use ReceptarWeb, :live_component

  alias Receptar.Units
  alias Receptar.Substances

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
    |> assign(substance_kind_value: ingredient.substance.kind)
  end

  defp assign_field_values(socket, _attrs), do: socket

  defp assign_amount_field_value(socket, ingredient) do
    amount = ingredient.amount
    socket
    |> assign(amount_value: if amount do Decimal.to_string(amount, :xsd) else "" end)
  end

  def handle_event("make-suggestion", %{"_target" => ["substance-name"]} = attrs, socket) do
    language = socket.assigns.language
    {:noreply,
     socket
     |> make_substance_suggestion(attrs)
     |> assign(substance_name_value: attrs["substance-name"])
     |> assign(substance_kind_value: Substances.name_to_kind(attrs["substance-name"], language))
    }
  end

  def handle_event("make-suggestion", %{"_target" => ["unit-name"]} = attrs, socket) do
    {:noreply,
     socket
     |> make_unit_suggestion(attrs)
     |> assign(unit_name_value: attrs["unit-name"])}
  end

  def handle_event("make-suggestion", %{"_target" => ["amount"]} = attrs, socket) do
    {:noreply,
     socket
     |> assign(amount_value: attrs["amount"])}
  end

  def handle_event("make-suggestion", %{"_target" => ["substance-kind"]} = attrs, socket) do
    {:noreply,
     socket
     |> assign(substance_kind_value: case attrs["substance-kind"] do
				       "vegan" -> :vegan
				       "vegetarian" -> :vegetarian
				       "meat" -> :meat
				       _ -> nil
				     end)}
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

  def handle_event("cancel", %{"number" => number}, socket) do
    number = String.to_integer(number)
    send_update(IngredientsLive, id: "ingredients", cancel: number)
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
