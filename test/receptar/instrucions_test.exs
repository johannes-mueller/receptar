defmodule Receptar.InstructionsTest do
  use Receptar.DataCase

  import Receptar.Seeder
  import Receptar.TestHelpers

  alias Receptar.Instructions

  describe "instructions" do
    setup do
      insert_test_data()
    end

    test "instructions of 'granda kino'"  do
      instructions = recipe_by_title("granda kino").instructions
      |> Instructions.translate("eo")
      assert [
	%{content: "kuiri nudelojn"},
	%{content: "aldoni tinuson"}
      ] = instructions
    end

    test "instructions of 'sardela pico'"  do
      instructions = recipe_by_title("sardela pico").instructions
      |> Instructions.translate("eo")
      assert [
	%{content: "fari paston"},
	%{content: "surmeti sardelojn"},
	%{content: "baki ĉion"},
      ] = instructions
    end

    test "instruction translations are preloaded" do
      [
	%{ translations: [ %{ language: "eo", content: "kuiri nudelojn" } ] },
	%{ translations: [ %{ language: "eo", content: "aldoni tinuson" } ] },
      ] = recipe_by_title("granda kino").instructions
    end
  end
end
