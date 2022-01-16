defmodule ReceptarWeb.Helpers do

  def determine_language(%{"language" => language}), do: language
  def determine_language(%{language: language}), do: language
  def determine_language(%{}), do: ReceptarWeb.Cldr.default_locale.language

  def insert_number_at(numbers, number) do
    [
      number |
      numbers
      |> Enum.map(fn
	i when i >= number -> i + 1
	i -> i
      end)
    ]
  end


end
