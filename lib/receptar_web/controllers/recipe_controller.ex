defmodule ReceptarWeb.RecipeController do
  use ReceptarWeb, :controller

  alias Receptar.Recipes

  def new(conn, _params) do
    language = conn.assigns.language
    render(conn, "new.html", language: language)
  end

  def create(conn, %{"title" => title}) do
    language = conn.assigns.language
    case Recipes.create_recipe(%{translations: [%{language: language, content: title}]}) do
      {:ok, recipe} ->
	conn |> redirect(to: "/recipe/#{recipe.id}")
      {:error, changeset} ->
	%{changes: %{translations: [%Ecto.Changeset{} = changeset]}} = changeset
	%{changes: %{language: language}} = changeset
	conn |> render("new.html", changeset: changeset, language: language)
    end
  end

  def query_recipe(%{"id" => id} = _params, language) do
     Recipes.get_recipe!(id)
    |> Recipes.translate(language)
  end
end
