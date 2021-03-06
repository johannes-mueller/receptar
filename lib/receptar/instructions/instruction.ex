defmodule Receptar.Instructions.Instruction do
  use Ecto.Schema
  import Ecto.Changeset
  alias Receptar.Translations

  schema "instructions" do
    belongs_to :recipe, Receptar.Recipes.Recipe
    has_many :translations, Receptar.Translations.Translation

    field :number, :integer

    timestamps()
  end

  @doc false
  def changeset(instruction, attrs) do
    instruction
    |> cast(attrs, [:number, :recipe_id])
    |> cast_assoc(:translations)
    |> validate_required([])
  end

  def update_changeset(instruction, attrs) do
    instruction
    |> cast(attrs, [:number, :recipe_id])
    |> update_translations(attrs)
  end

  defp update_translations(
    %{data: instruction} = changeset,
    %{language: _l, content: _c} = translation
  ) do

    instruction = if not Ecto.assoc_loaded?(instruction.translations) do
      Map.put(instruction, :translations, [])
    else
      instruction
    end

    instruction = Map.put_new(instruction, :translations, [])
    new_translation = Translations.update_translations_changeset(instruction, translation)

    %{changeset | changes: Map.put(changeset.changes, :translations, new_translation)}
  end
  defp update_translations(changeset, _attrs) do
    changeset
  end

end
