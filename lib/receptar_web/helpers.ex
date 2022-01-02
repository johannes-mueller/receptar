defmodule ReceptarWeb.Helpers do

  def determine_language(%{"language" => language}), do: language
  def determine_language(%{language: language}), do: language
  def determine_language(%{}), do: "eo"

end
