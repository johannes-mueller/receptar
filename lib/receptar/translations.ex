defmodule Receptar.Translations do
  alias Receptar.Repo
  import Ecto.Query

  alias Receptar.Translations.Translation

  def add_translation(translatable, translation) do
    foreign_key = foreign_key_of_translation(translatable)
    attrs = Map.put(translation, foreign_key, translatable.id)

    %Translation{}
    |> Translation.changeset(attrs)
    |> Repo.insert
  end

  def add_translation_changeset(translatable, translation) do
    foreign_key = foreign_key_of_translation(translatable)
    attrs = Map.put(translation, foreign_key, translatable.id)

    %Translation{}
    |> Translation.changeset(attrs)
    |> then(& %{&1 | action: :insert})
  end

  def add_translations(translatable, translations) do
    translations
    |> Enum.each(&(add_translation(translatable, &1)))
  end

  def update_translation(translation, attrs) do
    translation
    |> Translation.changeset(attrs)
    |> Repo.update
  end

  def update_translation_changeset(translation, attrs) do
    translation
    |> Translation.changeset(attrs)
    |> then(& %{&1 | action: :update})
  end

  def update_translations(translatable, attrs) do
    language = attrs.language
    translation = translatable.translations
    |> Enum.reduce(%{attrs.language => add_translation_changeset(translatable, attrs)},
		    fn
		      %{language: ^language} = tl, acc ->
			%{acc | attrs.language => update_translation_changeset(tl, attrs)}
		      %{language: language} = tl, acc ->
			Map.put(acc, language, zero_changeset(tl))
    end)
    |> Map.values
  end

  defp zero_changeset(tl) do
    Ecto.Changeset.cast(tl, %{}, [])
    |> then(& %{&1 | action: :update})
  end

  def translation_for_language(translations, language) do
    translations
    |> Enum.filter(&(&1.language == language))
    |> List.first
    |> content_or_translation_missing
  end

  def known_languages do
    Repo.all(from tl in Translation,
      group_by: tl.language,
      select: tl.language
    )
  end

  defp content_or_translation_missing(nil), do: :translation_missing
  defp content_or_translation_missing(%{content: content}), do: content

  defp foreign_key_of_translation(translatable) do
    case translatable do
      %Receptar.Substances.Substance{} -> :substance_id
      %Receptar.Instructions.Instruction{} -> :instruction_id
      %Receptar.Units.Unit{} -> :unit_id
      %Receptar.Recipes.Recipe{} -> :recipe_id
    end
  end
end
