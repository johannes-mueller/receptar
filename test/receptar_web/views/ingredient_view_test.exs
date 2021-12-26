defmodule ReceptarWeb.IngredientViewTest do
  use ReceptarWeb.ConnCase, async: true

  import Receptar.Seeder
  import Receptar.TestHelpers

  alias ReceptarWeb.IngredientView

  describe "IngredientView" do
    setup do
      insert_test_data()
      {:ok, %{id: some_valid_ingredient().id}}
    end

    @tag :skip
    test "render amount integer" do
      assert IngredientView.render_amount(%{amount: Decimal.new("1.0")}) == "1"
    end

    test "render amount float" do
      assert IngredientView.render_amount(%{amount: Decimal.new("1.3")}) == "1.3"
    end

  end
end
