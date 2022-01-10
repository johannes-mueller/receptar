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
    |> assign_submit_disabled
  end

  defp assign_field_values(socket, _attrs), do: socket

  defp assign_amount_field_value(socket, ingredient) do
    amount = ingredient.amount
    socket
    |> assign(amount_value: if amount do Decimal.to_string(amount, :xsd) else "" end)
  end

  defp assign_submit_disabled(socket) do
    socket
    |> assign(submit_disabled: submit_disabled(socket.assigns))
  end

  defp submit_disabled(%{
	amount_value: amount,
	unit_name_value: unit_name,
	substance_name_value: substance_name,
	substance_kind_value: substance_kind
       }) when
  amount != "" and
  unit_name != "" and
  substance_name !="" and
  not is_nil(substance_kind), do: false

  defp submit_disabled(_assigns), do: true

  def handle_event("submit", attrs, socket) do
    amount = Decimal.new(attrs["amount"])

    substance_kind = extract_substance_kind(attrs)

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

  def handle_event("change-event", attrs, socket) do
    socket = handle_input_change_event(attrs, socket)
    {:noreply,
     socket
     |> assign(submit_disabled: submit_disabled(socket.assigns))
    }
  end

  defp handle_input_change_event(%{"_target" => ["substance-name"]} = attrs, socket) do
    language = socket.assigns.language
    socket
    |> make_substance_suggestion(attrs)
    |> assign(substance_name_value: attrs["substance-name"])
    |> assign(substance_kind_value: Substances.name_to_kind(attrs["substance-name"], language))
  end

  defp handle_input_change_event(%{"_target" => ["unit-name"]} = attrs, socket) do
    socket
    |> make_unit_suggestion(attrs)
    |> assign(unit_name_value: attrs["unit-name"])
  end

  defp handle_input_change_event(%{"_target" => ["amount"]} = attrs, socket) do
    socket
    |> assign(amount_value: attrs["amount"])
  end

  defp handle_input_change_event(%{"_target" => ["substance-kind"]} = attrs, socket) do
    socket
    |> assign(substance_kind_value: extract_substance_kind(attrs))
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

  defp extract_substance_kind(attrs) do
    case attrs["substance-kind"] do
      "meat" -> :meat
      "vegan" -> :vegan
      "vegetarian" -> :vegetarian
      _ -> nil
    end
  end
end
