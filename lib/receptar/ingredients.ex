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

  def translate(ingredients, language) when is_list(ingredients) do
    Enum.map(ingredients, & translate(&1, language))
  end

  def translate(ingredient, language) do
    ingredient
    |> Map.put(:substance, Receptar.Substances.translate(ingredient.substance, language))
    |> Map.put(:unit, Receptar.Units.translate(ingredient.unit, language))
  end
end
