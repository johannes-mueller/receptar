defmodule ReceptarWeb.Helpers do
  use ReceptarWeb, :controller

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
