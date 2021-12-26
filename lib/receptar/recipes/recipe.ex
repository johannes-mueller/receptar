defmodule Receptar.Recipes.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  alias Receptar.Repo
  alias Receptar.Ingredients.Ingredient
  alias Receptar.Instructions.Instruction

  schema "recipes" do
    has_many :translations, Receptar.Translations.Translation
    has_many :ingredients, Receptar.Ingredients.Ingredient, on_replace: :delete
    has_many :instructions, Receptar.Instructions.Instruction, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(recipe, attrs) do
    attrs = Map.put_new(attrs, :language, nil)
    recipe
    |> cast(attrs, [])
    |> cast_assoc(:translations)
    |> put_assoc(:ingredients, cast_new_ingredients(attrs))
    |> put_assoc(:instructions, cast_new_instructions(attrs))
    |> validate_required([])
  end

  defp cast_new_ingredients(%{ingredients: ingredients, language: language}) do
    Enum.map(ingredients, & cast_if_new_ingredient(&1, language))
  end

  defp cast_new_ingredients(_attrs) do
    cast_new_ingredients(%{ingredients: [], language: nil})
  end

  defp cast_if_new_ingredient(%Ingredient{} = ingredient, _language), do: ingredient
  defp cast_if_new_ingredient(ingredient, language) do
    Ingredient.changeset(%Ingredient{}, Map.put(ingredient, :language, language))
    |> Repo.insert!
  end

  defp cast_new_instructions(%{instructions: instructions, language: language}) do
    Enum.map(instructions, & cast_if_new_instruction(&1, language))
  end

  defp cast_new_instructions(_attrs) do
    cast_new_instructions(%{instructions: [], language: nil})
  end

  defp cast_if_new_instruction(%Instruction{} = instruction, _language), do: instruction
  defp cast_if_new_instruction(instruction, language) do
    Instruction.changeset(%Instruction{}, maybe_retranslate(instruction, language))
    |> Repo.insert!
  end

  defp maybe_retranslate(instruction, language) do
    case instruction do
      %{translations: _translations} -> instruction
      _ -> Map.put(instruction, :translations, [%{
						   language: language,
						   content: instruction.content
						}])
    end
  end
end
