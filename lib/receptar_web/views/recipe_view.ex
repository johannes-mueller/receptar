defmodule ReceptarWeb.RecipeView do
  use ReceptarWeb, :view

  alias ReceptarWeb.RecipeLive
  alias ReceptarWeb.InstructionsLive
  alias ReceptarWeb.IngredientsLive

  def search_result_title(0), do: gettext("No recipes found.")
  def search_result_title(1), do: gettext("One recipe found.")
  def search_result_title(number), do: gettext("%{number} recipes found.", number: number)
end
