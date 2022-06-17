defmodule ReceptarWeb.CldrTest do
  import Assertions
  use ReceptarWeb.ConnCase
  use ReceptarWeb, :controller

  test "test default locale" do
    locale = ReceptarWeb.Cldr.default_locale
    assert locale.language == "eo"
  end

  test "known locales" do
    assert_lists_equal ReceptarWeb.Cldr.known_locale_names(), ["eo", "de", "sk"]
  end
end
