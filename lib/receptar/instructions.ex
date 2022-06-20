defmodule Receptar.Instructions do
  alias Receptar.Repo

  alias Receptar.Instructions.Instruction
  alias Receptar.Translations

  def translate(instructions, language) when is_list(instructions) do
    Enum.map(instructions, & translate(&1, language))
  end

  def translate(instruction, language) do
    translation = Translations.translation_for_language(instruction.translations, language)
    Map.put(instruction, :content, translation)
  end

  def update_translation(instruction, attrs) do
    instruction
    |> Instruction.update_changeset(attrs)
    |> Repo.update
  end
end
