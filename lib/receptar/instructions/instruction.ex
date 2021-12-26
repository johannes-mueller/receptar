defmodule Receptar.Instructions.Instruction do
  use Ecto.Schema
  import Ecto.Changeset

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
end
