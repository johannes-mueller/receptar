defmodule Receptar.TranslatablesTest do
  import Assertions
  use Receptar.DataCase

  import Receptar.Seeder
  import Receptar.TestHelpers

  alias Receptar.Substances
  alias Receptar.Units
  alias Receptar.Translations

  describe "translations" do
    setup do
      insert_test_data()
    end

    test "add a translation to a substance actually adds it" do
      substance = substance_by_name("salo")
      Translations.add_translation(substance, %{language: "sk", content: "soľ"})

      translations = substance_by_name("salo").translations
      [
	%{language: "eo", content: "salo"},
	%{language: "de", content: "Salz"},
	%{language: "sk", content: "soľ"}
      ] = translations
    end


    test "update_translations add new_translation" do
      substance = substance_by_name("salo")
      translations = [%{language: "sk", content: "soľ"} | substance.translations]

      Translations.update_translations(substance, translations)

      assert [
	%{language: "eo", content: "salo"},
	%{language: "de", content: "Salz"},
	%{language: "sk", content: "soľ"},
      ] = substance_by_name("salo").translations

    end

    test "update_translations change translation does not duplicate" do
      substance = substance_by_name("salo")
      translations = substance.translations
      |> Enum.map(fn
	%{language: "eo"} -> %{language: "eo", content: "saaalo"}
	tr -> tr
      end)

      Translations.update_translations(substance, translations)

      Substances.get!(substance.id).translations
      |> Enum.all?(fn
	%{language: "de", content: "Salz"} -> true
	%{language: "eo", content: "saaalo"} -> true
	_ -> false
      end)
      |> assert
    end

    test "update translations add new translation" do
      substance = substance_by_name("salo")

      translations = [%{language: "sk", content: "soľ"} | substance.translations]
      Translations.update_translations(substance, translations)

      assert [
	%{language: "eo", content: "salo"},
	%{language: "de", content: "Salz"},
	%{language: "sk", content: "soľ"},
      ] = Substances.get!(substance.id).translations
    end

    test "update translations change translation" do
      substance = substance_by_name("salo")
      translations =
	substance.translations
	|> Enum.map(fn
	  %{language: "eo"} -> %{language: "eo", content: "saalo"}
	  tr -> tr
        end)

      Translations.update_translations(substance, translations)

      assert [
	%{language: "de", content: "Salz"},
	%{language: "eo", content: "saalo"},
      ] = Enum.sort(Substances.get!(substance.id).translations)
    end

    test "add a multiple translations to a substance actually adds them" do
      substance = substance_by_name("salo")
      new_translations = [
	%{language: "sk", content: "soľ"},
	%{language: "fr", content: "sel"},
      ]
      Translations.add_translations(substance, new_translations)

      translations = substance_by_name("salo").translations
      assert [
	%{language: "eo", content: "salo"},
	%{language: "de", content: "Salz"},
	%{language: "sk", content: "soľ"},
	%{language: "fr", content: "sel"},
      ] = translations
    end

    test "add a translation to a unit actually adds it" do
      unit = Units.get_by_translation("gramo", "eo")
      Translations.add_translation(unit, %{language: "sk", content: "gram"})

      unit = Units.get_unit!(Units.get_by_translation("gramo", "eo").id)
      assert [
	%{language: "eo", content: "gramo"},
	%{language: "de", content: "Gramm"},
	%{language: "sk", content: "gram"}
      ] = unit.translations
    end

    test "add a translation to an instruction actually adds it" do
      instruction = recipe_by_title("granda kino").instructions |> List.first
      Translations.add_translation(instruction, %{language: "de", content: "Nudeln kochen"})

      translations = recipe_by_title("granda kino").instructions
      |> List.first
      |> Map.get(:translations)
      assert [
	%{language: "eo", content: "kuiri nudelojn"},
	%{language: "de", content: "Nudeln kochen"},
      ] = translations
    end

    test "add a translation to a recipe actually adds it" do
      recipe = recipe_by_title("granda kino")
      Translations.add_translation(recipe, %{language: "sk", content: "Veľké kino"})

      translations = recipe_by_title("granda kino").translations

      assert [
	%{language: "eo", content: "Granda kino"},
	%{language: "de", content: "Großes Kino"},
	%{language: "sk", content: "Veľké kino"}
      ] = translations
    end

    test "known languages are [eo, de]" do
      assert_lists_equal Translations.known_languages(), ["eo", "de"]
    end
  end

  describe "translations without empty database" do

    test "empty database does not know languages" do
      assert Translations.known_languages() == []
    end

  end

end
