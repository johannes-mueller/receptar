defmodule Receptar.RecipeTest do
  import Assertions
  use Receptar.DataCase

  import Receptar.Seeder

  alias Receptar.Recipes
  alias Receptar.Recipes.Recipe
  alias Receptar.Substances
  alias Receptar.Instructions.Instruction
  alias Receptar.Units
  alias Receptar.Orderables

  defp to_language_string_map(substances) do
    substances
    |> Enum.map(&(&1.translations))
    |> Enum.map(&extract_translation/1)
  end

  defp extract_translation translations do
    translations
    |> Enum.map(&({&1.language, &1.content}))
    |> Enum.into(%{})
  end

  describe "recipes" do
    setup do
      insert_test_data()
    end

    test "get unknown recipe raises NoResultsError" do
      assert_raise Ecto.NoResultsError, fn -> Recipes.get_recipe!(2342) end
    end

    test "search unknown recipe in unknown language returns empty list" do
      result = Recipes.search(%{"title" => "foo"}, "eo")
      assert result == []
    end

    test "search 'granda kino' in Esperanto returns 'granda kino' entry" do
      result = Recipes.search(%{"title" => "granda kino"}, "eo") |> to_language_string_map
      assert result == [%{"eo" => "Granda kino", "de" => "Großes Kino"}]
    end

    test "search 'sa' in German returns 'Sardela pico' entry" do
      result = Recipes.search(%{"title" => "sa"}, "eo") |> to_language_string_map
      assert result == [
	%{"eo" => "Sardela pico", "de" => "Sardellenpizza"},
	%{"eo" => "Tinusa bulko", "de" => "Thunfischbrötchen"}
      ]
    end

    test "search 'bulko' in Esperanto finds the three 'bulko' recipes" do
      assert [
	%Recipe { translations: [%{content: "Fromaĝa bulko"}, _]},
	%Recipe { translations: [%{content: "Sukera bulko"}, _]},
	%Recipe { translations: [%{content: "Tinusa bulko"}, _]}
      ] = Recipes.search(%{"title" => "bulko"}, "eo")
    end

    test "search substance tinuso finds 'granda kino' and 'tinusa bulko'" do
      substance = Substances.search("tinuso", "eo") |> List.first

      assert [
	%Recipe { translations: [%{content: "Granda kino"}, _]},
	%Recipe { translations: [%{content: "Tinusa bulko"}, _]}
      ] = Recipes.search(%{"substance" => [substance.id]}, "eo")
    end

    test "search substance tinuso and 'bulko' 'tinusa bulko'" do
      substance = Substances.search("tinuso", "eo") |> List.first

      assert [
	%Recipe { translations: [%{content: "Tinusa bulko"}, _]}
      ] = Recipes.search(%{"substance" => [substance.id], "title" => "bulko"}, "eo")
    end

    test "search substance tinuso and substance nudeloj finds 'granda kino'" do
      substance_1 = Substances.search("tinuso", "eo") |> List.first
      substance_2 = Substances.search("nudeloj", "eo") |> List.first

      assert [
	%Recipe { translations: [%{content: "Granda kino"}, _]}
      ] = Recipes.search(%{"substance" => [substance_1.id, substance_2.id]}, "eo")
    end

    test "search 'bulko' and vegetarian finds 'Fromaĝa bulko' and 'Sukera bulko'" do
      result = Recipes.search(%{"title" => "bulko", "class" => "vegetarian"}, "eo")
      |> Recipes.translate("eo")
      |> Enum.map(& &1.title)

      assert_lists_equal result, ["Sukera bulko", "Fromaĝa bulko"]
    end

    test "search 'bulko' and vegan finds 'Sukera bulko'" do
      assert [
	%Recipe { translations: [%{content: "Sukera bulko"}, _]},
      ] = Recipes.search(%{"title" => "bulko", "class" => "vegan"}, "eo")
    end

    test "search recipe returns substance kind fields set" do
      recipe =
	Recipes.search(%{"title" => "granda kino"}, "eo")
        |> List.first
        |> Recipes.translate("eo")

      assert [
	%{substance: %{name: "nudeloj", kind: :vegan}},
	%{substance: %{name: "tinuso", kind: :meat}},
	%{substance: %{name: "salo", kind: :vegan}},
      ] = recipe.ingredients
    end

    test "unknown search parameter does not fail" do
      Recipes.search(%{"foo" => "bar"}, "eo")
    end

    test "get known recipe returns recipe" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first

      result = %{ Recipes.get_recipe!(recipe.id) | ingredients: [], instructions: []}
      assert result == %{ recipe | ingredients: [], instructions: [] }
    end

    test "translated title of recipe 'Großes Kino' to Esperanto is 'Granda kino'" do
      recipe = Recipes.search(%{"title" => "Großes Kino"}, "de") |> List.first

      result = Recipes.get_recipe!(recipe.id)
      |> Recipes.translate("eo")
      assert %{title: "Granda kino"} = result
    end

    test "translated title of recipe 'granda kino' to German is 'Großes Kino'" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first

      result = Recipes.get_recipe!(recipe.id)
      |> Recipes.translate("de")
      assert %{title: "Großes Kino"} = result
    end

    test "translated title of recipe 'granda kino' to unknown language is :translation_missing" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first

      result = Recipes.get_recipe!(recipe.id)
      |> Recipes.translate("vo")
      assert %{title: :translation_missing} = result
    end

    test "translated title of searched recipe 'Großes Kino'" do
      result = Recipes.search(%{"title" => "Großes Kino"}, "de")
      |> Recipes.translate("de")
      assert [%{title: "Großes Kino"}] = result
    end

    test "translated description of searched recipe 'Großes Kino' to German" do
      result = Recipes.search(%{"title" => "Großes Kino"}, "de")
      |> Recipes.translate("de")
      assert [%{description: "Echt ganz großes Kino"}] = result
    end

    test "translated description of searched recipe 'Großes Kino' to Esperanto" do
      result = Recipes.search(%{"title" => "Großes Kino"}, "de")
      |> Recipes.translate("eo")
      assert [%{description: "Vere granda kino"}] = result
    end

    test "translated description of searched recipe 'Großes Kino' to unknown" do
      result = Recipes.search(%{"title" => "Großes Kino"}, "de")
      |> Recipes.translate("und")
      assert [%{description: :translation_missing}] = result
    end

    test "translated description of searched recipe 'Sardellenpizza' to Esperanto" do
      result = Recipes.search(%{"title" => "Sardellenpizza"}, "de")
      |> Recipes.translate("eo")
      assert [%{description: nil}] = result
    end

    test "translated instruction names of recipe 'Großes Kino' to Esperanto" do
      result = Recipes.search(%{"title" => "Großes Kino"}, "de")
      |> Recipes.translate("eo")
      |> List.first

      assert %Recipe{
	instructions: [
	  %{content: "kuiri nudelojn"},
	  %{content: "aldoni tinuson"},
	]
      } = result
    end

    test "translated ingredients of recipe 'Großes Kino' to Esperanto" do
      result = Recipes.search(%{"title" => "Großes Kino"}, "de")
      |> Recipes.translate("eo")
      |> List.first

      assert %Recipe{
	ingredients: [
	  %{substance: %{name: "nudeloj"}},
	  %{substance: %{name: "tinuso"}},
	  %{substance: %{name: "salo"}},
	]
      } = result
    end

    test "translated ingredient units of recipe 'Großes Kino' to Esperanto" do
      result = Recipes.search(%{"title" => "Großes Kino"}, "de")
      |> Recipes.translate("eo")
      |> List.first

      assert %Recipe{
	ingredients: [
	  %{unit: %{name: "kilogramo"}},
	  %{unit: %{name: "gramo"}},
	  %{unit: %{name: "gramo"}},
	]
      } = result
    end

    test "servings number of recipe is present" do
      result = Recipes.search(%{"title" => "Großes Kino"}, "de")
      |> Recipes.translate("eo")
      |> List.first

      assert result.servings == 2
    end

    test "delete known recipe actually deletes it" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first

      {:ok, deleted} = Recipes.delete_recipe(recipe)
      assert deleted.id == recipe.id

      assert_raise Ecto.NoResultsError, fn -> Recipes.get_recipe!(recipe.id) end
    end

    test "recipe 'granda kino' contains 'tinuso' and 'nudeloj' and 'salo'" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first

      recipe = Recipes.get_recipe!(recipe.id)
      |> Recipes.translate("eo")

      assert [
	%{substance: %{name: "nudeloj", kind: :vegan}},
	%{substance: %{name: "tinuso", kind: :meat}},
	%{substance: %{name: "salo", kind: :vegan}},
      ] = recipe.ingredients
    end

    test "recipe 'sardela pico' contains 'pasto' and 'sardeloj' and 'salo'" do
      recipe = Recipes.search(%{"title" => "sardela pico"}, "eo") |> List.first

      recipe = Recipes.get_recipe!(recipe.id)
      |> Recipes.translate("eo")

      assert [
	%{substance: %{name: "pasto", kind: :vegan}},
	%{substance: %{name: "sardeloj", kind: :meat}},
	%{substance: %{name: "salo", kind: :vegan}},
      ] = recipe.ingredients
    end

    test "recipe 'fromaĝa bulko' contains 'pasto' and 'fromago'" do
      recipe = Recipes.search(%{"title" => "fromaĝa bulko"}, "eo") |> List.first

      recipe = Recipes.get_recipe!(recipe.id)
      |> Recipes.translate("eo")

      assert [
	%{substance: %{name: "pasto", kind: :vegan}},
	%{substance: %{name: "fromago", kind: :vegetarian}},
      ] = recipe.ingredients
    end

    test "create an empty recipe" do
      recipe_initials = %{
	translations: [%{language: "sk", content: "Bryndzové halušky"}]
      }
      assert {:ok, %Recipe{id: id}} =
	Recipes.create_recipe(recipe_initials)

      assert %{
	servings: 2,
	translations: [%{language: "sk", content: "Bryndzové halušky"}],
	ingredients: [],
	instructions: []
      } = Recipes.get_recipe!(id)
    end

    test "translate an empty recipe" do
      {:ok, recipe} = Recipes.create_recipe(%{})

      assert recipe
      |> Repo.preload([:translations])
      |> Recipes.translate("eo")
      |> then(& &1.title) == :translation_missing
    end

    test "create recipe actually adds it" do
      substance_1 = Substances.search("pasto", "eo") |> List.first
      substance_2 = Substances.search("fromago", "eo") |> List.first

      unit_id_1 = Units.get_by_translation("kilogramo", "eo").id
      unit_id_2 = Units.get_by_translation("gramo", "eo").id

      recipe =  %{
	servings: 3,
	translations: [
	  %{language: "eo", content: "Fromaĝa pico"}
	],
	ingredients: [
	  %{amount: 1.0, unit_id: unit_id_1, substance_id: substance_1.id},
	  %{amount: 0.5, unit_id: unit_id_2, substance_id: substance_2.id}
	],
	instructions: [
	  %{number: 1, translations: [%{language: "eo", content:  "fari paston"}]},
	  %{number: 2, translations: [%{language: "eo", content:  "surmeti fromaĝon"}]},
	  %{number: 3, translations: [%{language: "eo", content:  "baki ĉion"}]}
	]
      }

      assert {:ok, %Receptar.Recipes.Recipe{id: id}} = Recipes.create_recipe(recipe)
      assert id > 0

      recipe = Recipes.get_recipe!(id)

      assert %Recipe{
	id: ^id,
	servings: 3,
	translations: [
	  %{content: "Fromaĝa pico"}
	],
	# ingredients: [
	#   %Ingredient{substance_id: ^substance_id_1, unit_id: ^unit_id_1},
	#   %Ingredient{}
	# ],
	instructions: [
	  %Instruction{recipe_id: ^id, number: 1, translations: [%{content: "fari paston"}]},
	  %Instruction{recipe_id: ^id, number: 2, translations: [%{content: "surmeti fromaĝon"}]},
	  %Instruction{recipe_id: ^id, number: 3, translations: [%{content: "baki ĉion"}]}
	]
      } = recipe
    end

    test "update recipe with empty change attrs changes nothing" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo")
      |> List.first

      assert Recipes.update_recipe(recipe, %{}) == {:ok, recipe}
    end

    test "update recipe title" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo")
      |> List.first

      {:ok, updated} = Recipes.update_recipe(recipe, %{title: "grandega kino", language: "eo"})
      assert updated
      |> Recipes.translate("eo")
      |> then(& &1.title) == "grandega kino"

      assert updated
      |> Recipes.translate("de")
      |> then(& &1.title) == "Großes Kino"

      old_translation_ids = recipe.translations
      |> Enum.map(& &1.id)

      updated_translation_ids = updated.translations
      |> Enum.map(& &1.id)

      assert_lists_equal updated_translation_ids, old_translation_ids
    end

    for {language, title} <- [{"eo", "Grandega kino"}, {"de", "Epochales Theater"}] do
      test "change title (#{language}) of recipe" do
	language = unquote(language)
	title = unquote(title)

	recipe = Recipes.search(%{"title" => "granda kino"}, "eo")
	|> List.first
	|> Recipes.translate(language)

	Recipes.update_recipe(recipe, %{title: title, language: language})

	new_recipe = Recipes.get_recipe!(recipe.id)
	|> Recipes.translate(language)

	assert new_recipe.title == title

	assert new_recipe.ingredients == recipe.ingredients

      end
    end

    test "add description new" do
      recipe = Recipes.search(%{"title" => "sardela pico"}, "eo")
      |> List.first
      |> Recipes.translate("eo")

      Recipes.update_recipe(recipe, %{description: "Vera sardela pico", language: "eo"})

      new_recipe = Recipes.get_recipe!(recipe.id)
      |> Recipes.translate("eo")

      assert new_recipe.description == "Vera sardela pico"
    end

    test "change description" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo")
      |> List.first
      |> Recipes.translate("eo")

      Recipes.update_recipe(recipe, %{description: "Vere grandeeega kino", language: "eo"})

      new_recipe = Recipes.get_recipe!(recipe.id)
      |> Recipes.translate("eo")

      assert new_recipe.description == "Vere grandeeega kino"
    end

    test "add description translation" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo")
      |> List.first
      |> Recipes.translate("eo")

      Recipes.update_recipe(recipe, %{description: "naozaj skvelé kino", language: "sk"})

      new_recipe = Recipes.get_recipe!(recipe.id)
      |> Recipes.translate("sk")

      assert new_recipe.description == "naozaj skvelé kino"
    end


    test "add ingredient with known substance actually adds it" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first
      id = recipe.id

      unit_id = Units.get_by_translation("gramo", "eo").id

      recipe = Recipes.get_recipe!(id)

      new_ingredient = %{
	amount: Decimal.from_float(70.0),
	unit_id: unit_id,
	substance: %{name: "lakto"}
      }

      {_number, ingredients} = Orderables.append(recipe.ingredients, new_ingredient)

      Recipes.update_recipe(recipe, %{ingredients: ingredients, language: "eo"})

      recipe = Recipes.get_recipe!(recipe.id) |> Recipes.translate("eo")

      ingredients = recipe
        |> then(& &1.ingredients)
        |> Enum.map(& &1.substance.name)

      assert ingredients == ["nudeloj", "tinuso", "salo", "lakto"]

      substance_id = recipe
        |> then(& &1.ingredients)
        |> List.last()
        |> then(& &1.substance.id)

      known_substance =
	Substances.search("lakto", "eo")
        |> List.first()

      assert substance_id == known_substance.id
    end

    test "add ingredient (eo) to recipe actually adds it" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first
      id = recipe.id

      unit_id = Units.get_by_translation("gramo", "eo").id

      recipe = Recipes.get_recipe!(id)

      new_ingredient = %{
	amount: Decimal.from_float(70.0),
	unit_id: unit_id,
	substance: %{name: "kaporoj"}
      }

      {_number, ingredients} = Orderables.append(recipe.ingredients, new_ingredient)

      Recipes.update_recipe(recipe, %{ingredients: ingredients, language: "eo"})

      ingredients = Recipes.get_recipe!(recipe.id) |> Recipes.translate("eo")
      |> then(& &1.ingredients)
      |> Enum.map(& &1.substance.name)

      assert ingredients == ["nudeloj", "tinuso", "salo", "kaporoj"]
    end

    test "add ingredient (de) to recipe actually adds it" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first
      id = recipe.id

      unit_id = Units.get_by_translation("gramo", "eo").id

      recipe = Recipes.get_recipe!(id)

      new_ingredient = %{
	amount: Decimal.from_float(70.0),
	unit_id: unit_id,
	substance: %{name: "Kapern"}
      }

      {_number, ingredients} = Orderables.append(recipe.ingredients, new_ingredient)

      Recipes.update_recipe(recipe, %{ingredients: ingredients, language: "de"})

      ingredients = Recipes.get_recipe!(recipe.id) |> Recipes.translate("de")
      |> then(& &1.ingredients)
      |> Enum.map(& &1.substance.name)

      assert ingredients == ["Pasta", "Thunfisch", "Salz", "Kapern"]
    end

    test "add ingredient unknown unit (eo) to recipe actually adds it" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first
      id = recipe.id

      recipe = Recipes.get_recipe!(id)

      new_ingredient = %{
	amount: Decimal.from_float(70.0),
	unit: %{name: "litroj"},
	substance: %{name: "lakto"}
      }

      {_number, ingredients} = Orderables.append(recipe.ingredients, new_ingredient)

      Recipes.update_recipe(recipe, %{ingredients: ingredients, language: "eo"})

      unit =
        Recipes.get_recipe!(recipe.id)
        |> then(& &1.ingredients)
        |> List.last()
        |> then(& &1.unit)

      assert %{translations: [%{language: "eo", content: "litroj"}]} = unit
    end

    test "add ingredient unknown unit (de) to recipe actually adds it" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first
      id = recipe.id

      recipe = Recipes.get_recipe!(id)

      new_ingredient = %{
	amount: Decimal.from_float(70.0),
	unit: %{name: "Liter"},
	substance: %{name: "Milch"}
      }

      {_number, ingredients} = Orderables.append(recipe.ingredients, new_ingredient)

      Recipes.update_recipe(recipe, %{ingredients: ingredients, language: "de"})

      unit =
        Recipes.get_recipe!(recipe.id)
        |> then(& &1.ingredients)
        |> List.last()
        |> then(& &1.unit)

      assert %{translations: [%{language: "de", content: "Liter"}]} = unit
    end

    test "delete ingredient from recipe actually deletes it" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first

      ingredient = List.first(recipe.ingredients)

      substance_id = ingredient.substance_id

      ingredients = Orderables.delete(recipe.ingredients, ingredient)

      Recipes.update_recipe(recipe, %{ingredients: ingredients})

      substances = Recipes.search(%{"title" => "granda kino"}, "eo")
      |> List.first
      |> then(& &1.ingredients)
      |> Enum.map(& &1.substance_id)

      refute substance_id in substances
      assert length(substances) == length(recipe.ingredients) - 1

    end

    test "add untranslated instruction to recipe actually adds it" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first
      id = recipe.id

      recipe = Recipes.get_recipe!(id)
      |> Recipes.translate("eo")

      new_instruction = %{content: "aldoni kaporojn"}

      recipe.instructions
      |> Enum.map(& %{number: &1.number, content: &1.content})

      {_number, instructions} = Orderables.append(recipe.instructions, new_instruction)

      Recipes.update_recipe(recipe, %{language: "eo", instructions: instructions})

      instructions = Recipes.get_recipe!(recipe.id) |> Recipes.translate("eo")
      |> then(& &1.instructions)
      |> Enum.map(& &1.content)

      assert_lists_equal instructions, ["kuiri nudelojn", "aldoni tinuson", "aldoni kaporojn"]
    end

    test "delete instruction from recipe actually deletes it" do
      recipe = Recipes.search(%{"title" => "granda kino"}, "eo") |> List.first

      instruction = List.first(recipe.instructions)

      instructions = Orderables.delete(recipe.instructions, instruction)

      Recipes.update_recipe(recipe, %{instructions: instructions})

      instructions = Recipes.search(%{"title" => "granda kino"}, "eo")
      |> List.first
      |> then(& &1.instructions)

      refute instruction.id in instructions
      assert length(instructions) == length(recipe.instructions) - 1

    end

  end
end
