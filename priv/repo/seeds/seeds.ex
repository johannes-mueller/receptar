defmodule Receptar.Seeder.Helpers do

  def make_id_hash({:ok, %{id: id, translations: translations}}, acc) do
    eo_translation = translations
    |> Receptar.Translations.translation_for_language("eo")

    Map.put(acc, eo_translation, id)
  end

  def make_recipes(recipes_data, substances, units) do
    recipes_data
    |> Enum.map(&make_translations/1)
    |> Enum.map(fn recipe_data -> make_ingredients(recipe_data, substances, units) end)
#    |> Enum.map(&make_instructions/1)
  end

  defp make_ingredients(recipe_data, substances, units) do
    ingredients = recipe_data.ingredients
    |> Enum.map(fn {number, name, amount, unit} ->
      %{
	number: number,
	substance_id: substances[name],
	amount: amount,
	unit_id: units[unit]
      }
    end)
    %{recipe_data | ingredients: ingredients}
  end

  defp make_instructions(recipe_data) do
    instructions = recipe_data.instructions
    |> Enum.map(&make_translations/1)
  end

  def make_translations(%{} = data_map) do
    translations = data_map.translations
    |> Enum.map(fn {lang, content} -> %{
				      "language" => Atom.to_string(lang),
				      "content" => content
				  }
    end)
    %{data_map | translations: translations}
  end
end

defmodule Receptar.Seeder do
  import Receptar.Seeder.Helpers

  alias Receptar.Substances
  alias Receptar.Units
  alias Receptar.Recipes

  @substances [
    %{
      "translations" => [
      %{"language" => "eo", "content" => "salo"},
      %{"language" => "de", "content" => "Salz"}
    ],
      "meat" => :false, "animal" => false},
    %{
      "translations" => [
      %{"language" => "eo", "content" => "sukero"},
      %{"language" => "de", "content" => "Zucker"}
    ],
      "meat" => :false, "animal" => false},
    %{
      "translations" => [
      %{"language" => "eo", "content" => "pasto"},
      %{"language" => "de", "content" => "Teig"}
    ],
      "meat" => :false, "animal" => false},
    %{
      "translations" => [
      %{"language" => "eo", "content" => "nudeloj"},
      %{"language" => "de", "content" => "Pasta"}
    ],
      "meat" => :false, "animal" => false},
    %{
      "translations" => [
      %{"language" => "eo", "content" => "suko"},
      %{"language" => "de", "content" => "Saft"}
    ],
      "meat" => :false, "animal" => false},
    %{
      "translations" => [
      %{"language" => "eo", "content" => "lakto"},
      %{"language" => "de", "content" => "Milch"}
    ],
      "meat" => false, "animal" => true},
    %{
      "translations" => [
      %{"language" => "eo", "content" => "hakita viando"},
      %{"language" => "de", "content" => "Hackfleisch"}
    ],
      "meat" => true, "animal" => true},
    %{
      "translations" => [
      %{"language" => "eo", "content" => "fromago"},
      %{"language" => "de", "content" => "Käse"}
    ],
      "meat" => false, "animal" => true},
    %{
      "translations" => [
      %{"language" => "eo", "content" => "tinuso"},
      %{"language" => "de", "content" => "Thunfisch"}
    ],
      "meat" => true, "animal" => true},
    %{
      "translations" => [
      %{"language" => "eo", "content" => "sardeloj"},
      %{"language" => "de", "content" => "Sardellen"}
    ],
      "meat" => true, "animal" => true}
  ]

  @units [
    %{"translations" => [
       %{"language" => "eo", "content" => "gramo"},
       %{"language" => "de", "content" => "Gramm"},
     ]
     },
    %{"translations" => [
      %{"language" => "eo", "content" => "kilogramo"},
      %{"language" => "de", "content" => "Kilogramm"},
    ]
    },
    %{"translations" => [
      %{"language" => "eo", "content" => "kulereto"},
      %{"language" => "de", "content" => "Teelöffel"}
    ]
    }
  ]

  @recipes [
    %{
      translations: [eo: "Granda kino", de: "Großes Kino"],
      ingredients: [
	{2, "tinuso", 250.0, "gramo"},
	{1, "nudeloj", 0.5, "kilogramo"},
	{3, "salo", 1.3, "gramo"}
      ],

      instructions: [
	%{
	  number: 1,
	  translations: [%{"language" => "eo", "content" => "kuiri nudelojn"}]
	},
	%{
	  number: 2,
	  translations: [%{"language" => "eo", "content" => "aldoni tinuson"}]
	},
      ]
    },
    %{
      translations: [eo: "Sardela pico", de: "Sardellenpizza"],
      ingredients: [
	{2, "sardeloj", 150.0, "gramo"},
	{1, "pasto", 1.0, "kilogramo"},
	{3, "salo", 1.5, "gramo"}
      ],
      instructions: [
	%{
	  number: 2,
	  translations: [%{"language" => "eo", "content" => "surmeti sardelojn"}]
	},
	%{
	  number: 3,
	  translations: [%{"language" => "eo", "content" => "baki ĉion"}]
	},
	%{
	  number: 1,
	  translations: [%{"language" => "eo", "content" => "fari paston"}]
	}
      ]
    },
    %{
      translations: [eo: "Fromaĝa bulko", de: "Käsebrötchen"],
      ingredients: [
	{1, "pasto", 200, "gramo"},
	{2, "fromago", 20, "gramo"},
      ],
      instructions: []
    },
    %{
      translations: [eo: "Sukera bulko", de: "Zuckerbrötchen"],
      ingredients: [
	{1, "pasto", 200, "gramo"},
	{2, "sukero", 20, "gramo"},
      ],
      instructions: []
    },
    %{
      translations: [eo: "Tinusa bulko", de: "Thunfischbrötchen"],
      ingredients: [
	{1, "pasto", 200, "gramo"},
	{2, "tinuso", 20, "gramo"},
      ],
      instructions: []
    }
  ]

  def insert_test_data do
    substances = @substances
    |> Enum.map(&Substances.create_substance/1)
    |> Enum.reduce(%{}, &make_id_hash/2)

    units = @units
    |> Enum.map(&Units.create_unit/1)
    |> Enum.reduce(%{}, &make_id_hash/2)

    @recipes
    |> make_recipes(substances, units)
    |> Enum.map(&Recipes.create_recipe/1)
  end

end
