defmodule Receptar.Ingredients do
  alias Receptar.Repo
  alias Receptar.Ingredients.Ingredient

  def get_ingredient!(id) do
    Repo.get!(Ingredient, id)
    |> Repo.preload([
      {:substance, :translations},
      {:unit, :translations}
    ])
  end

  def translate([ingredient | tail], language) do
    [translate(ingredient, language) | translate(tail, language)]
  end

  def translate([], _language), do: []

  def translate(ingredient, language) do
    ingredient
    |> Map.put(:substance, Receptar.Substances.translate(ingredient.substance, language))
    |> Map.put(:unit, Receptar.Units.translate(ingredient.unit, language))
  end
end
