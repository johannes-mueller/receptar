defmodule Receptar.Substances.Substance do
  use Ecto.Schema
  import Ecto.Changeset
  alias Receptar.Substances.Substance
  alias Ecto.Changeset

  schema "substances" do
    has_many :translations, Receptar.Translations.Translation
    field :meat, :boolean, default: false
    field :animal, :boolean, default: false

    field :kind, :any, default: nil, virtual: true
    field :name, :string, virtual: true

    timestamps()
  end

  def is_vegan(%{kind: :vegan}), do: true
  def is_vegan(%{animal: false}), do: true
  def is_vegan(%{}), do: false

  def is_vegetarian(%{kind: :vegetarian}), do: true
  def is_vegetarian(%{kind: :vegan}), do: true
  def is_vegetarian(%{meat: false}), do: true
  def is_vegetarian(%{}), do: false

  def is_vegetarian_non_vegan(substance) do
    is_vegetarian(substance) and not is_vegan(substance)
  end

  def is_meat(%{kind: :meat}), do: true
  def is_meat(%{meat: true}), do: true
  def is_meat(%{}), do: false

  @doc false
  def changeset(substance, attrs) do
    substance
    |> cast(attrs, [:animal, :meat])
    |> cast_assoc(:translations)
    |> evaluate_kind_field(attrs)
    |> validate_vegan_vegetarian
  end

  defp evaluate_kind_field(changeset, attrs) do
    kind_bits = case attrs do
		  %{kind: :vegan} -> %{meat: false, animal: false}
		  %{kind: :vegetarian} -> %{meat: false, animal: true}
		  %{kind: :meat} -> %{meat: true, animal: true}
		  _ -> %{}
		end

    kind_bits
    |> Enum.map(fn {key, val} -> {key, val != Map.from_struct(changeset.data)[key]} end)

    %{changeset | data: Map.merge(changeset.data, kind_bits)}
  end

  defp validate_vegan_vegetarian(changeset) do
    case changeset do
      %Changeset{
	changes: %{animal: false},
	data: %Substance{meat: true}
      } -> %{changeset | valid?: false}
      %Changeset{
	changes: %{animal: true, meat: true}
      } -> changeset
      %Changeset{
	changes: %{meat: true},
	data: %Substance{animal: false}
      } -> %{changeset | valid?: false}
      _ -> changeset
    end
  end
end
