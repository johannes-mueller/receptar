defmodule Receptar.Units do
  import Ecto.Query

  alias Receptar.Repo
  alias Receptar.Units.Unit

  alias Receptar.Translatables
  alias Receptar.Translations

  alias Receptar.Translations.Translation

  def get_unit!(id) do
    Repo.get!(Unit, id)
    |> Repo.preload([:translations])
  end

  def get_by_translation(name, language) do
    Repo.all(from u in Unit,
      join: t in Translation, on: t.unit_id == u.id,
      where: t.language == ^language and t.content == ^name,
      select: u)
    |> List.first
  end

  def completion_candidates(search_string, language) do
    Translatables.all_translations_starting_with(search_string, language, :unit)
    |> Translatables.only_the_string_itself
  end

  def create_unit(attrs) do
    %Unit{}
    |> Unit.changeset(attrs)
    |> Repo.insert
  end

  def translate(unit, language) do
    translation = Translations.translation_for_language(unit.translations, language)
    Map.put(unit, :name, translation)
  end
end
