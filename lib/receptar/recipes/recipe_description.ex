defmodule Receptar.Recipes.RecipeDescription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipe_descriptions" do
    belongs_to :recipe, Receptar.Recipes.Recipe
    has_many :translations, Receptar.Translations.Translation

    timestamps()
  end

  @doc false
  def changeset(recipe_description, attrs) do
    recipe_description
    |> cast(attrs, [])
    |> cast_assoc(:translations)
    |> validate_required([])
  end

  def translate(nil = _recipe_description, _language), do: nil
  def translate(recipe_description, language) do
    Receptar.Translations.translation_for_language(recipe_description.translations, language)
  end
end
