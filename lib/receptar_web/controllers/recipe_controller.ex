defmodule ReceptarWeb.RecipeController do
  use ReceptarWeb, :controller

  alias Receptar.Recipes
  alias ReceptarWeb.Helpers

  def search(conn, params) do
    language = conn.assigns.language

    recipes = params
    |> Enum.map(&sanitize_parameters/1)
    |> Enum.into(%{})
    |> Recipes.search(language)
    |> Recipes.translate(language)

    render(conn, "search.html", recipes: recipes)
  end

  def new(conn, params) do
    language = conn.assigns.language
    render(conn, "new.html", language: language)
  end

  def create(conn, %{"language" => _, "content" => _c} = translation) do
    case Recipes.create_recipe(%{translations: [translation]}) do
      {:ok, recipe} ->
	conn |> redirect(to: "/recipe/#{recipe.id}")
      {:error, changeset} ->
	%{changes: %{translations: [%Ecto.Changeset{} = changeset]}} = changeset
	%{changes: %{language: language}} = changeset
	conn |> render("new.html", changeset: changeset, language: language)
    end
  end

  def query_recipe(%{"id" => id} = params, language) do
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
