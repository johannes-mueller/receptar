defmodule Receptar.IngredientsTest do

  use Receptar.DataCase

  alias Receptar.Ingredients
  alias Receptar.Ingredients.Ingredient
  alias Receptar.Substances
  alias Receptar.Recipes
  alias Receptar.Units

  import Receptar.Seeder

  describe "ingredients" do
    setup do
      insert_test_data()
    end

    defp some_ingredient do
      Recipes.search(%{:title => "granda kino"}, "eo")
      |> Recipes.translate("de")
      |> List.first
      |> then(&(&1.ingredients))
      |> Enum.filter(& &1.name == "Pasta")
      |> List.first
    end

    test "get unknown ingredient raises NoResultsError" do
      assert_raise Ecto.NoResultsError, fn -> Ingredients.get_ingredient!(2342) end
    end

    test "get known ingredient returns the ingredient" do
      ingredient = some_ingredient()

      assert Decimal.compare(ingredient.amount, Decimal.from_float(0.5)) == :eq
      assert ingredient.unit_id == Units.get_by_translation("kilogramo", "eo").id

      substance = Substances.search("nudeloj", "eo") |> List.first

      assert %{ingredient.substance | translations: nil} == %{substance | translations: nil}
    end

    test "translate ingredient to Esperanto" do
      translated = some_ingredient()
      |> Ingredients.translate("eo")

      assert %Ingredient{} = translated
      assert translated.name == "nudeloj"
    end

    test "translate ingredient to German" do
      translated = some_ingredient()
      |> Ingredients.translate("de")

      assert translated.name == "Pasta"
    end

    test "translate ingredients of recipe 1 to Esperanto" do
      translated = Recipes.search(%{:title => "granda kino"}, "eo")
      |> List.first
      |> then(&(&1.ingredients))
      |> Ingredients.translate("eo")
      |> Enum.map(& &1.name)

      assert ["nudeloj", "tinuso", "salo"] == translated
    end

    test "add new ingredient with unknown substance" do
      unit = Units.get_by_translation("gramo", "eo")

      attrs = %{
	amount: Decimal.new("125"), unit_id: unit.id, substance: %{name: "rizo"},
	language: "eo"
      }

      ingredient = Ingredient.changeset(%Ingredient{}, attrs)
      |> Repo.insert!
      |> Repo.preload([{:substance, :translations}])

      assert %{
	substance: %{translations: [%{language: "eo", content: "rizo"}]}
      } = ingredient
    end
  end
end
