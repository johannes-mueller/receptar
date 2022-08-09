defmodule Receptar.Ingredients.Ingredient do
  alias Receptar.Repo

  use Ecto.Schema
  import Ecto.Changeset

  alias Receptar.Substances.Substance
  alias Receptar.Units.Unit

  schema "ingredients" do
    field :number, :integer
    field :amount, :decimal
    belongs_to :substance, Receptar.Substances.Substance
    belongs_to :unit, Receptar.Units.Unit
    belongs_to :recipe, Receptar.Recipes.Recipe

    timestamps()
  end

  @doc false
  def changeset(ingredient, attrs) do
    attrs =
      attrs
      |> Map.put_new(:language, nil)

    ingredient
    |> cast(attrs, [:number, :amount, :unit_id, :substance_id, :recipe_id])
    |> put_assoc(:unit, cast_if_new_unit(attrs))
    |> put_assoc(:substance, cast_if_new_substance(attrs))
    |> validate_required([:amount])
  end


  defp cast_if_new_unit(%{unit_id: id}) do
    Receptar.Units.get_unit!(id)
  end

  defp cast_if_new_unit(%{unit: unit, language: language}) do
    Receptar.Units.get_by_translation(unit.name, language) ||
      Unit.changeset(%Unit{}, maybe_retranslate(unit, language))
      |> Repo.insert!
  end

  defp cast_if_new_substance(%{substance_id: id}) do
    Receptar.Substances.get!(id)
  end

  defp cast_if_new_substance(%{substance: substance, language: language}) do
    Receptar.Substances.get_by_translation(substance.name, language) ||
      Substance.changeset(%Substance{}, maybe_retranslate(substance, language))
      |> Repo.insert!
  end

  defp maybe_retranslate(substance, language) do
    case substance do
      %{translations: _translations} -> substance
      _ -> Map.put(substance, :translations, [%{
						   language: language,
						   content: substance.name
						}])
    end
  end

end
