defmodule Receptar.Substances do
  import Ecto.Query

  alias Receptar.Repo
  alias Receptar.Substances.Substance

  alias Receptar.Translatables
  alias Receptar.Translations
  alias Receptar.Translations.Translation

  def search(search_string, language) do
    Translatables.all_matching_translations(search_string, language, :substance)
    |> Translatables.all_matching_of_kind(:substance)
    |> Enum.map(&fill_kind_field/1)
  end

  def get_by_translation(name, language) do
    Repo.all(from s in Substance,
      join: t in Translation, on: t.substance_id == s.id,
      where: t.language == ^language and t.content == ^name,
      select: s)
    |> List.first
    |> Repo.preload([:translations])
  end

  def completion_candidates("", _language), do: []

  def completion_candidates(search_string, language) do
    Translatables.all_translations_starting_with(search_string, language, :substance)
    |> Translatables.only_the_string_itself
  end

  def create_substance(attrs) do
    %Substance{}
    |> Substance.changeset(attrs)
    |> Repo.insert
  end

  def get!(id) do
    Repo.get!(Substance, id)
    |> Repo.preload([:translations])
    |> fill_kind_field
  end

  def get(id) do
    Repo.get(Substance, id)
    |> Repo.preload([:translations])
    |> fill_kind_field
  end

  def delete_substance(%Substance{} = substance) do
    Repo.delete(substance)
  end

  def update_substance(substance, params) do
    substance
    |> Substance.changeset(params)
    |> Repo.update
  end

  def fill_kind_field(nil = _substance), do: nil

  def fill_kind_field(substance) do
    kind = case substance do
	     %{meat: true} -> :meat
	     %{animal: true, meat: false} -> :vegetarian
	     %{animal: false, meat: false} -> :vegan
	     _ -> :nil
	   end
    Map.put(substance, :kind, kind)
  end

  def translate([substance | tail], language) do
    [translate(substance, language) | translate(tail, language)]
  end

  def translate([], _language), do: []

  def translate(substance, language) do
    translation = Translations.translation_for_language(substance.translations, language)
    Map.put(substance, :name, translation)
  end

  def name_to_kind(substance_name, language) do
    substance =
      get_by_translation(substance_name, language)

    substance && substance |> fill_kind_field |> then(& &1.kind)
  end
end
