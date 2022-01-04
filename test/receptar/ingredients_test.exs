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
      |> Enum.filter(& &1.substance.name == "Pasta")
      |> List.first
    end

    test "get unknown ingredient raises NoResultsError" do
      assert_raise Ecto.NoResultsError, fn -> Ingredients.get_ingredient!(2342) end
    end

    test "get known ingredient returns the ingredient" do
      ingredient = some_ingredient()

      assert Decimal.compare(ingredient.amount, Decimal.from_float(0.5)) == :eq
      assert ingredient.unit_id == Units.get_by_translation("kilogramo", "eo").id

      substance =
	Substances.search("nudeloj", "eo")
        |> List.first
        |> Substances.translate("de")

      assert %{ingredient.substance | translations: nil} == %{substance | translations: nil}
    end

    test "translate ingredient substance to Esperanto" do
      translated = some_ingredient()
      |> Ingredients.translate("eo")

      assert %Ingredient{} = translated
      assert translated.substance.name == "nudeloj"
    end

    test "translate ingredient substance to German" do
      translated = some_ingredient()
      |> Ingredients.translate("de")

      assert translated.substance.name == "Pasta"
    end

    test "translate ingredient unit to Esperanto" do
      translated = some_ingredient()
      |> Ingredients.translate("eo")

      assert %Ingredient{} = translated
      assert translated.unit.name == "kilogramo"
    end

    test "translate ingredient unit to German" do
      translated = some_ingredient()
      |> Ingredients.translate("de")

      assert translated.unit.name == "Kilogramm"
    end

    test "translate ingredients of recipe 1 to Esperanto" do
      translated = Recipes.search(%{:title => "granda kino"}, "eo")
      |> List.first
      |> then(&(&1.ingredients))
      |> Ingredients.translate("eo")

    translated_substances =
      translated
      |> Enum.map(& &1.substance.name)

      assert ["nudeloj", "tinuso", "salo"] == translated_substances

    translated_units =
      translated
      |> Enum.map(& &1.unit.name)

      assert ["kilogramo", "gramo", "gramo"] == translated_units
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
