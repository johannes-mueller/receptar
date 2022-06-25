defmodule Receptar.Translations.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "translations" do
    field :content, :string
    field :language, :string
    belongs_to :substance, Receptar.Substances.Substance
    belongs_to :recipe, Receptar.Recipes.Recipe
    belongs_to :unit, Receptar.Units.Unit
    belongs_to :instruction, Receptar.Instructions.Instruction

    timestamps()
  end

  @doc false
  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:content, :language, :substance_id, :instruction_id, :unit_id, :recipe_id])
    |> validate_required([:content, :language])
  end

end
