defmodule Receptar.TestHelpers do

  alias Receptar.Recipes
  alias Receptar.Substances

  def recipe_by_title(title) do
    Recipes.search(%{"title" => title}, "eo")
    |> List.first
    |> Receptar.Repo.preload([:instructions])
  end

  def substance_by_name(name) do
    Substances.search(name, "eo")
    |> List.first
  end

  def recipe_id(title) do
    recipe_by_title(title).id
  end

  def recipe_url(title) do
    idstring = recipe_id(title) |> Integer.to_string
    "/recipe/" <> idstring
  end

  def recipe_url_edit(title), do: recipe_url(title) <> "/edit"

  def some_valid_ingredient() do
    substance = %Receptar.Substances.Substance{
      id: 2342,
      name: "salo"
    }
    %{
      id: 2342,
      number: 2,
      amount: Decimal.new("1.3"),
      unit: %{name: "gramo"},
      substance: substance
    }
  end

end
