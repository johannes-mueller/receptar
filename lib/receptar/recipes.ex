defmodule Receptar.Recipes do
  alias Receptar.Repo
  import Ecto.Query

  alias Receptar.Recipes.Recipe
  alias Receptar.Recipes.RecipeDescription
  alias Receptar.Instructions.Instruction
  alias Receptar.Instructions
  alias Receptar.Ingredients.Ingredient
  alias Receptar.Ingredients
  alias Receptar.Substances
  alias Receptar.Translations

  def search(criteria, language) do
    base_query()
    |> build_query(criteria, language)
    |> Repo.all
    |> preload_assocs
    |> Enum.map(&fill_ingredients_kind_fields/1)
  end

  def get_recipe!(id) do
    Repo.get!(Recipe, id)
    |> preload_assocs
    |> fill_ingredients_kind_fields
  end

  def create_recipe(attrs) do
    %Recipe{}
    |> Recipe.changeset(attrs)
    |> Repo.insert()
  end

  def update_recipe(%Recipe{} = recipe, attrs) do
    attrs = Map.put_new(attrs, :language, nil)

    recipe
    |> Recipe.update_changeset(attrs)
    |> Repo.update
  end

  def delete_recipe(recipe) do
    Repo.delete(recipe)
  end

  def translate([recipe | tail], language) do
    [translate(recipe, language) | translate(tail, language)]
  end

  def translate([], _language), do: []

  def translate(recipe, language) do
    translation = Translations.translation_for_language(recipe.translations, language)

    recipe
    |> Map.put(:title, translation)
    |> Map.put(:description, RecipeDescription.translate(recipe.recipe_description, language))
    |> Map.put(:ingredients, Ingredients.translate(recipe.ingredients, language))
    |> Map.put(:instructions, Instructions.translate(recipe.instructions, language))
  end

  defp base_query do
    from rp in Recipe
  end

  defp build_query(query, criteria, language) do
    criteria
    |> spread_language_parameter_to_all_criteria(language)
    |> Enum.reduce(query, &compose_query/2)
  end

  defp spread_language_parameter_to_all_criteria(criteria, language) do
    criteria
    |> Enum.map(fn el -> [el] |> Enum.into(%{}) |> Map.put(:language, language) end)
  end

  defp compose_query(%{"title" => title, language: language}, query) do
    query
    |> join(:left, [r], t in assoc(r, :translations), as: :translations)
    |> where([_r, translations: t], ilike(t.content, ^"%#{title}%")
	     and t.language == ^language
	     and not is_nil(field(t, :recipe_id)))
  end

  defp compose_query(%{"substance" => substances}, query) do
    substance_list_length = length(substances)
    query
    |> join(
      :left, [r], i in subquery(query_substances(substances)),
      on: r.id == i.recipe_id,
      as: :ingredients
    )
    |> where([_r,  ingredients: i], i.count == ^substance_list_length)
  end

  defp compose_query(%{"class" => "vegetarian"}, query) do
    query
    |> join(:left, [r], i in subquery(query_vegetarian()), as: :i, on: r.id == i.recipe_id)
    |> where([_r, i: i], i.vegetarian == true)
  end

  defp compose_query(%{"class" => "vegan"}, query) do
    query
    |> join(:left, [r], i in subquery(query_vegan()), as: :i, on: r.id == i.recipe_id)
    |> where([_r, i: i], i.vegan == true)
  end

  defp compose_query(_unknown_parmeter, query), do: query

  defp query_substances(substance_list) do
    from(i in Ingredient)
    |> where([i], i.substance_id in ^substance_list)
    |> group_by([i], i.recipe_id)
    |> select([i], %{recipe_id: i.recipe_id, count: count()})
  end

  defp query_vegetarian do
    from(i in Ingredient)
    |> join(:left, [i], s in assoc(i, :substance))
    |> group_by([i, s], [i.recipe_id])
    |> select(
      [i, s], %{
	recipe_id: i.recipe_id,
	vegetarian: fragment(
	  "CASE WHEN SUM(CASE WHEN ? THEN 1 ELSE 0 END) = 0 THEN true ELSE false END",
	  s.meat)
      }
    )
  end

  defp query_vegan do
    from(i in Ingredient)
    |> join(:left, [i], s in assoc(i, :substance))
    |> group_by([i, s], [i.recipe_id])
    |> select(
      [i, s], %{
	recipe_id: i.recipe_id,
	vegan: fragment(
	  "CASE WHEN SUM(CASE WHEN ? THEN 1 ELSE 0 END) = 0 THEN true ELSE false END",
	  s.animal)
      }
    )
  end

  defp preload_assocs(recipe_s) do
    recipe_s
    |> Repo.preload(
      [
	:translations,
	recipe_description: :translations,
	ingredients: from(i in Ingredient,
	  order_by: i.number,
	  preload: [{:substance, :translations}, {:unit, :translations}]
	),
	instructions: from(i in Instruction,
	  order_by: i.number,
	  preload: [:translations])
      ]
    )
  end

  def fill_ingredients_kind_fields(recipe) do
    ingredients =
      recipe.ingredients
      |> Enum.map(& %{&1 | substance: Substances.fill_kind_field(&1.substance)})

    %{recipe | ingredients: ingredients}
  end
end
