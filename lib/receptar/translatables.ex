defmodule Receptar.Translatables do
  alias Receptar.Repo
  import Ecto.Query

  def all_matching_translations(search_string, language, kind) do
    search_query("%#{search_string}%", language, kind)
    |> Repo.all()
  end

  def all_translations_starting_with(search_string, language, kind) do
    search_query("#{search_string}%", language, kind)
    |> Repo.all
  end

  def all_matching_of_kind(translations, kind) do
    translations
    |> Repo.preload([kind])
    |> Enum.map(&(Map.get(&1, kind)))
    |> Repo.preload([:translations])
  end

  def only_the_string_itself(translations) do
    translations
    |> Enum.map(&(&1.content))
  end

  defp search_query(wildcard_search, language, kind) do
    kind_id = make_kind_id(kind)
    from tl in Receptar.Translations.Translation,
      where: ilike(tl.content, ^wildcard_search) and tl.language == ^language
        and not is_nil(field(tl, ^kind_id)),
      order_by: tl.content
  end

  defp make_kind_id(:substance), do: :substance_id
  defp make_kind_id(:unit), do: :unit_id

end
