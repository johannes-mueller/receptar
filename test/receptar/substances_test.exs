defmodule Receptar.SubstancesTest do
  use Receptar.DataCase

  alias Receptar.Substances
  alias Receptar.Substances.Substance

  import Receptar.Seeder

  defp to_language_string_map(substances) do
    substances
    |> Enum.map(&(&1.translations))
    |> Enum.map(&extract_translation/1)
  end

  defp extract_translation translations do
    translations
    |> Enum.map(&({&1.language, &1.content}))
    |> Enum.into(%{})
  end

  describe "substances" do
    setup do
      insert_test_data()
    end

    test "search unknown in unknown language substance returns empty list" do
      result = Substances.search("foo", "vo")
      assert result == []
    end

    test "search 'sal' in Esperanto returns 'salo' entry" do
      result = Substances.search("sal", "eo") |> to_language_string_map
      assert result == [%{"eo" => "salo", "de" => "Salz"}]
    end

    test "search 'alo' in Esperanto returns 'salo' entry" do
      result = Substances.search("alo", "eo") |> to_language_string_map
      assert result == [%{"eo" => "salo", "de" => "Salz"}]
    end

    test "search 'alz' in Esperanto returns 'salo' entry" do
      result = Substances.search("alz", "eo") |> to_language_string_map
      assert result == []
    end

    test "search 'alz' in German returns 'salo' entry" do
      result = Substances.search("alz", "de") |> to_language_string_map
      assert result == [%{"eo" => "salo", "de" => "Salz"}]
    end

    test "search 'sal' in German returns 'salo' entry" do
      result = Substances.search("sal", "de") |> to_language_string_map
      assert result == [%{"eo" => "salo", "de" => "Salz"}]
    end

    test "search 'past' in Esperanto returns 'pasto' entry" do
      result = Substances.search("past", "eo") |> to_language_string_map
      assert result == [%{"eo" => "pasto", "de" => "Teig"}]
    end

    test "search 'past' in German returns 'nudeloj' entry" do
      result = Substances.search("past", "de") |> to_language_string_map
      assert result == [%{"eo" => "nudeloj", "de" => "Pasta"}]
    end

    test "search 'suk' in Esperanto returns 'sukero' and 'suko' entries" do
      result = Substances.search("suk", "eo") |> to_language_string_map
      assert result == [
	%{"eo" => "sukero", "de" => "Zucker"},
	%{"eo" => "suko", "de" => "Saft"}
      ]
    end

    test "search 'sa' in German returns 'suko' and 'salo' entries" do
      result = Substances.search("sa", "de") |> to_language_string_map
      assert result == [
	%{"eo" => "suko", "de" => "Saft"},
	%{"eo" => "salo", "de" => "Salz"},
	%{"eo" => "sardeloj", "de" => "Sardellen"}
      ]
    end

    test "get completion candidates for unknown returns empty list" do
      result = Substances.completion_candidates("foo", "vo")
      assert result == []
    end

    test "get completion for 'sal' in Esperanto returns 'salo'" do
      result = Substances.completion_candidates("sal", "eo")
      assert result == ["salo"]
    end

    test "get completion for 'su' in Esperanto returns 'sukero, suko'" do
      result = Substances.completion_candidates("su", "eo")
      assert result == ["sukero", "suko"]
    end

    test "get completion for 'sa' in German returns 'Saft, Salz'" do
      result = Substances.completion_candidates("sa", "de")
      assert result == ["Saft", "Salz", "Sardellen"]
    end

    test "get completion for 'al' in Esperanto returns empty list" do
      result = Substances.completion_candidates("al", "eo")
      assert result == []
    end

    test "completion candidates for empty string should be empty" do
      result = Substances.completion_candidates("", "eo")
      assert result == []
    end

    test "'salo' entry is vegan" do
      entry = Substances.search("salo", "eo") |> List.first
      assert entry.meat == :false
      assert entry.animal == :false
      assert entry.kind == :vegan
    end

    test "'lakto' entry is vegetarian" do
      entry = Substances.search("lakto", "eo") |> List.first
      assert entry.meat == :false
      assert entry.animal == :true
    end

    test "'hakita viando' entry is not vegetarian" do
      entry = Substances.search("hakita viando", "eo") |> List.first
      assert entry.meat == :true
      assert entry.animal == :true
    end

    for {name, kind} <- [{"salo", :vegan}, {"fromago", :vegetarian}, {"tinuso", :meat}] do
      test "#{name} entry is #{kind}" do
	entry = Substances.search(unquote(name), "eo") |> List.first
	assert entry.kind == unquote(kind)
      end
    end

    for {i, substance, expected} <- [
	  {1, %{name: ""}, false},
	  {2, %{kind: :vegan}, true},
	  {3, %{animal: false}, true}
	] do
	test "is_vegan/1 from #{i}" do
	  assert Substance.is_vegan(unquote(Macro.escape(substance))) == unquote(expected)
	end
    end

    for {i, substance, expected} <- [
	  {1, %{name: ""}, false},
	  {2, %{kind: :vegetarian}, true},
	  {3, %{kind: :vegan}, true},
	  {4, %{meat: false}, true}
	] do
	test "is_vegetarian/1 from #{i}" do
	  assert Substance.is_vegetarian(unquote(Macro.escape(substance))) == unquote(expected)
	end
    end

    for {i, substance, expected} <- [
	  {1, %{name: ""}, false},
	  {2, %{kind: :vegan}, false},
	  {3, %{kind: :vegetarian}, true},
	  {4, %{animal: true, meat: false}, true},
	  {5, %{animal: false, meat: false}, false}
	] do
	test "is_vegetarian_non_vegan/1 from #{i}" do
	  assert Substance.is_vegetarian_non_vegan(unquote(Macro.escape(substance))) == unquote(expected)
	end
    end

    for {i, substance, expected} <- [
	  {1, %{name: ""}, false},
	  {2, %{kind: :meat}, true},
	  {3, %{meat: true}, true}
	] do
	test "is_meat/1 from #{i}" do
	  assert Substance.is_meat(unquote(Macro.escape(substance))) == unquote(expected)
	end
    end

    for {kind, substance_name} <- [
	  {:vegan, "salo"},
	  {:vegetarian, "lakto"},
	  {:meat, "tinuso"},
	  {nil, "foo"}
	] do
	test "#{substance_name} name is #{kind}" do
	  assert Substances.name_to_kind(unquote(substance_name), "eo") == unquote(kind)
	end
    end

    test "insert one substance with one translation" do
      Substances.create_substance(
	%{
	  translations: [%{"language" => "eo", "content" => "pipro"}],
	}
      )
      result = Substances.search("pipro", "eo") |> to_language_string_map
      assert result == [%{"eo" => "pipro"}]
    end

    test "insert one substance with two translations" do
      Substances.create_substance(
	%{
	  translations: [
	    %{"language" => "eo", "content" => "pipro"},
	    %{"language" => "de", "content" => "Pfeffer"}
	  ],
	}
      )
      result = Substances.search("pipro", "eo") |> to_language_string_map
      assert result == [%{"eo" => "pipro", "de" => "Pfeffer"}]
    end

    test "insert one vegan substance check if vegan" do
      {:ok, substance} = Substances.create_substance(
	%{
	  translations: [%{"language" => "eo", "content" => "salo"}],
	}
      )
      assert substance.meat == :false
      assert substance.animal == :false
    end

    test "insert one vegetarian substance check if vegetarian" do
      {:ok, substance} = Substances.create_substance(
	%{
	  translations: [%{"language" => "eo", "content" => "lakto"}],
	  animal: :true
	}
      )
      assert substance.meat == :false
      assert substance.animal == :true
    end

    test "insert one non vegetarian substance check if non vegetarian" do
      {:ok, substance} = Substances.create_substance(
	%{
	  translations: [%{"language" => "eo", "content" => "viando"}],
	  animal: :true, meat: true
	}
      )
      assert substance.meat == :true
      assert substance.animal == :true
    end

    test "insert one vegan kind substance check if vegan" do
      {:ok, substance} = Substances.create_substance(
	%{
	  translations: [%{"language" => "eo", "content" => "salo"}],
	  kind: :vegan
	}
      )
      assert substance.meat == :false
      assert substance.animal == :false
    end

    test "insert one vegetarian kind substance check if vegetarian" do
      {:ok, substance} = Substances.create_substance(
	%{
	  translations: [%{"language" => "eo", "content" => "lakto"}],
	  kind: :vegetarian
	}
      )
      assert substance.meat == :false
      assert substance.animal == :true
    end

    test "insert one non vegetarian kind substance check if non vegetarian" do
      {:ok, substance} = Substances.create_substance(
	%{
	  translations: [%{"language" => "eo", "content" => "viando"}],
	  kind: :meat
	}
      )
      assert substance.meat == :true
      assert substance.animal == :true
    end

    test "get unknown substance raises Ecto.NoResultsError" do
      assert_raise Ecto.NoResultsError, fn -> Substances.get_substance!(2342) end
    end

    test "get known substance return substance" do
      substance = Substances.search("salo", "eo") |> List.first

      fetched_substance = Substances.get_substance!(substance.id)
      assert substance == fetched_substance
    end

    for {name, kind} <- [{"salo", :vegan}, {"fromago", :vegetarian}, {"tinuso", :meat}] do
      test "get #{name} is #{kind}" do
	substance = Substances.search(unquote(name), "eo") |> List.first
	fetched_substance = Substances.get_substance!(substance.id)

	assert fetched_substance.kind == unquote(kind)
      end
    end

    test "delete known substance actually deletes it" do
      substance = Substances.search("suko", "eo") |> List.first

      {:ok, %Substance{}} = Substances.delete_substance(substance)
      assert_raise Ecto.NoResultsError, fn -> Substances.get_substance!(substance.id) end
    end

    test "updating a known substance actually updates it" do
      substance = Substances.search("suko", "eo") |> List.first

      {:ok, substance} = Substances.update_substance(substance, %{animal: :true})

      assert substance.animal == :true
      assert Substances.get_substance!(substance.id).animal == :true
    end

    test "inserting a vegan non vegetarian substance fails" do
      vegana_viando = %{
	translations: [%{"language" => "eo", "content" => "vegana viando"}],
	animal: :false, meat: true
      }

      {:error, %Ecto.Changeset{}} = Substances.create_substance(vegana_viando)
    end

    test "changing to a vegan non vegetarian substance fails" do
      substance = Substances.search("hakita viando", "eo") |> List.first

      {:error, %Ecto.Changeset{}} = Substances.update_substance(substance, %{animal: false})
    end

    test "changing to a vegan vegetarian substance fails" do
      substance = Substances.search("salo", "eo") |> List.first

      {:error, %Ecto.Changeset{}} = Substances.update_substance(substance, %{meat: true})
    end
  end
end
