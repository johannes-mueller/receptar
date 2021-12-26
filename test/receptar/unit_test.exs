defmodule Receptar.UnitTest do
  use Receptar.DataCase

  alias Receptar.Units

  import Receptar.Seeder

  describe "units" do
    setup do
      insert_test_data()
    end

    test "search unknown unit in unknown language returns empty list" do
      result = Units.completion_candidates("foo", "vo")
      assert result == []
    end

    test "search 'g' for Esperanto returns ['gramo']" do
      result = Units.completion_candidates("g", "eo")
      assert result == ["gramo"]
    end

    test "search 'g' for German returns ['Gramm']" do
      result = Units.completion_candidates("g", "de")
      assert result == ["Gramm"]
    end

    test "search 'k' for Esperanto returns ['kilogramo', 'kulereto']" do
      result = Units.completion_candidates("k", "eo")
      assert result == ["kilogramo", "kulereto"]
    end

    test "search empty string returns all candidates" do
      result = Units.completion_candidates("", "eo")
      assert result == ["gramo", "kilogramo", "kulereto"]
    end

    test "create 'gramo' unit in Esperanto" do
      Units.create_unit(
	%{
	  translations: [%{"language" => "eo", "content" => "litro"}],
	}
      )
      result = Units.completion_candidates("l", "eo")
      assert result == ["litro"]
    end

    test "get unit by Esperanto translation" do
      id = Units.get_by_translation("gramo", "eo").id
      unit = Units.get_unit!(id)
      |> Units.translate("eo")

      assert unit.name == "gramo"
    end

  end
end
