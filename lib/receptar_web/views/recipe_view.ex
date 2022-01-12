defmodule ReceptarWeb.RecipeView do
  use ReceptarWeb, :view

  def search_result_title(0), do: gettext("No recipes found.")
  def search_result_title(1), do: gettext("One recipe found.")
  def search_result_title(number), do: gettext("%{number} recipes found.", number: number)
end
