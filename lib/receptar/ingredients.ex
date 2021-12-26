defmodule Receptar.Ingredients do
  alias Receptar.Repo
  alias Receptar.Ingredients.Ingredient
  alias Receptar.Recipes.Recipe
  alias Receptar.Translations

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
    translation = ingredient.substance.translations
    |> Translations.translation_for_language(language)

    ingredient
    |> Map.put(:name, translation)
    |> Map.put(:unit, Receptar.Units.translate(ingredient.unit, language))
  end
end
