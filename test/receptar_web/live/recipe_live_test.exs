defmodule ReceptarWeb.RecipeLiveTest do
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Phoenix.LiveViewTest

  import Receptar.Seeder
  import Receptar.TestHelpers

  alias Receptar.Recipes
  alias Receptar.Substances

  alias ReceptarWeb.RecipeLive

  defp create_socket() do
    %{socket: %Phoenix.LiveView.Socket{}}
  end

  describe "Socket state RecipeLiveTest" do
    setup do
      insert_test_data()
      create_socket()
    end

    for {name, language} <- [{"salo", "eo"}, {"Salz", "de"}] do
      test "submit ingredient known (#{language}) substance", %{socket: socket} do
	name = unquote(name)
	language = unquote(language)

	recipe_id = recipe_id("granda kino")

	{:ok, socket} =
	  RecipeLive.mount(%{"id" => recipe_id, "language" => language}, nil, socket)

	{:noreply, socket} =
	  RecipeLive.handle_info(
	    {
	      :submit_ingredient,
	      %{
		ingredient: %{
		  amount: Decimal.new("1"),
		  unit: %{name: "gramo"},
		  name: name,
		  substance_kind: :vegan,
		  number: 4
		},
		edit_instructions: []
	      }
	    },
	    socket
	  )

	new_ingredient =
	  socket.assigns.recipe.ingredients
          |> Enum.filter(& &1.number == 4)
        |> List.first

	known_substance = Substances.get_by_translation(name, language)

	assert new_ingredient.substance_id == known_substance.id
      end
    end

    for {language, content} <- [{"eo", "ĉion samtempe"}, {"de", "alles auf einmal"}] do
      test "submit instruction #{language}", %{socket: socket} do
	language = unquote(language)
	content = unquote(content)

	recipe_id = recipe_id("granda kino")

	{:ok, socket} =
	  RecipeLive.mount(%{"id" => recipe_id, "language" => language}, nil, socket)

	{:noreply, socket} =
	  RecipeLive.handle_info(
	    {
	      :submit_instruction,
	      %{
		instructions: [%{content: content, number: 1}],
		edit_instructions: []
	      }
	    },
	    socket
	  )

	assert [
	  %Receptar.Instructions.Instruction{
	    translations: [%{language: ^language, content: ^content}],
	    number: 1}
	] = socket.assigns.recipe.instructions

	assert [%{content: ^content}] = socket.assigns.recipe.instructions

	recipe = Recipes.get_recipe!(recipe_id) |> Recipes.translate(language)
	assert [%{content: ^content, number: 1}] = recipe.instructions
      end
    end

    for {number, remaining} <- [{1, "aldoni tinuson"}, {2, "kuiri nudelojn"}] do
      test "delete instruction #{number}", %{socket: socket} do
	number = unquote(number)
	remaining = unquote(remaining)
	recipe_id = recipe_id("granda kino")

	{:ok, socket} =
	  RecipeLive.mount(%{"id" => recipe_id}, nil, socket)

	{:noreply, socket} =
	  RecipeLive.handle_info(
	    {
	      :delete_instruction,
	      %{
		number: number,
		edit_instructions: []
	      }
	    },
	    socket
	  )

	instructions = socket.assigns.recipe.instructions
	assert length(instructions) == 1
	assert List.first(instructions).content == remaining
      end
    end
  end

  describe "Connection state" do
    setup do
      insert_test_data()
    end

    test "nothing", %{conn: conn} do
      id = recipe_id("granda kino")
      {:ok, view, _html} = live(conn, "/recipe/#{id}")
      send view.pid, :foo
    end
  end
end
