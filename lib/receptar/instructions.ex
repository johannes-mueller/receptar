defmodule Receptar.Instructions do
  alias Receptar.Repo

  alias Receptar.Instructions.Instruction
  alias Receptar.Translations

  def translate([instruction | tail], language) do
    [translate(instruction, language) | translate(tail, language)]
  end

  def translate([], _language), do: []

  def translate(instruction, language) do
    translation = Translations.translation_for_language(instruction.translations, language)
    Map.put(instruction, :content, translation)
  end
end
