defmodule Receptar.Units.Unit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "units" do
    has_many :translations, Receptar.Translations.Translation

    timestamps()
  end

  @doc false
  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [])
    |> cast_assoc(:translations)
    |> validate_required([])
  end
end
