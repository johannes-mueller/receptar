defmodule ReceptarWeb.RecipeController do
  use ReceptarWeb, :controller

  alias Receptar.Recipes
  alias ReceptarWeb.Helpers

  def search(conn, params) do
    language = Helpers.determine_language(params)
    recipes = params
    |> Enum.map(&sanitize_parameters/1)
    |> Enum.into(%{})
    |> Recipes.search(language)
    |> Recipes.translate(language)

    render(conn, "search.html", recipes: recipes)
  end

  def show(conn, params) do
    recipe = query_recipe(params)
    render(conn, "show.html", recipe: recipe)
  end

  def query_recipe(params) do
    language = Helpers.determine_language(params)
    params = params
    |> Enum.map(&sanitize_parameters/1)
    |> Enum.into(%{})

    %{"id" => id} = params
    Recipes.get_recipe!(id)
    |> Recipes.translate(language)
  end

  def sanitize_parameters({"substance", substance_list}) do
    substance_list = substance_list
    |> Enum.filter(&only_single_values/1)
    |> Enum.map(&Integer.parse/1)
    |> Enum.map(fn
      {i, _remainder} -> i
      :error -> :error
    end)
    |> Enum.filter(&(&1 != :error))

    {"substance", substance_list}
  end

  def sanitize_parameters({some_key, "true"}), do: {some_key, true}
  def sanitize_parameters({some_key, "false"}), do: {some_key, false}
  def sanitize_parameters(any_other_parameter), do: any_other_parameter

  defp only_single_values({_some_key, _some_value}), do: false
  defp only_single_values(_some_value), do: true

end
