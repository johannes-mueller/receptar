defmodule ReceptarWeb.IngredientLiveTest do
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Receptar.Seeder
  import Phoenix.LiveViewTest
  import Phoenix.LiveView.Helpers

  import Receptar.TestHelpers
  alias ReceptarWeb.IngredientLive
  alias ReceptarWeb.IngredientTestLiveView

  defp create_socket() do
    %{socket: %Phoenix.LiveView.Socket{}}
  end

  describe "Socket state" do
    setup do
      insert_test_data()
      create_socket()
    end

    test "suggestions for the substance when empty prefix", %{socket: socket} do
      assigns = %{id: 1, language: "eo"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{"_target" => ["substance-name"], "substance-name" => ""}
      {:noreply, socket} =
	IngredientLive.handle_event("make-suggestion", attrs, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{substance_suggestions: []}
      } = socket
    end

    test "substance prefix 'sa' in Esperanto suggests 'salo", %{socket: socket} do
      assigns = %{id: 1, language: "eo"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{"_target" => ["substance-name"], "substance-name" => "sa"}

      {:noreply, socket} =
	IngredientLive.handle_event("make-suggestion", attrs, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{substance_suggestions: ["salo", "sardeloj"]}
      } = socket
    end

    test "substance prefix 'sa' in German suggests 'Salz'", %{socket: socket} do
      assigns = %{id: 1, language: "de"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{"_target" => ["substance-name"], "substance-name" => "sa"}

      {:noreply, socket} =
	IngredientLive.handle_event("make-suggestion", attrs, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{substance_suggestions: ["Saft", "Salz", "Sardellen"]}
      } = socket
    end

    test "no unit prefix suggest them all Esperanto", %{socket: socket} do
      assigns = %{id: 1, language: "eo"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{unit_suggestions: ["gramo", "kilogramo", "kulereto"]}
      } = socket
    end

    test "no unit prefix suggest them all German", %{socket: socket} do
      assigns = %{id: 1, language: "de"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{unit_suggestions: ["Gramm", "Kilogramm", "Teelöffel"]}
      } = socket
    end

    test "unit prefix 'g' in Esperanto suggests 'gramo'", %{socket: socket} do
      assigns = %{id: 1, language: "eo"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{"_target" => ["unit-name"], "unit-name" => "g"}

      {:noreply, socket} =
	IngredientLive.handle_event("make-suggestion", attrs, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{unit_suggestions: ["gramo"]}
      } = socket
    end

    test "unit prefix 'g' in German suggests 'Gramm'", %{socket: socket} do
      assigns = %{id: 1, language: "de"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{"_target" => ["unit-name"], "unit-name" => "g"}

      {:noreply, socket} =
	IngredientLive.handle_event("make-suggestion", attrs, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{unit_suggestions: ["Gramm"]}
      } = socket
    end

    test "change in amount field does not crash", %{socket: socket} do
      assigns = %{id: 1, language: "eo"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{"_target" => ["amount"]}

      {:noreply, _socket} =
	IngredientLive.handle_event("make-suggestion", attrs, socket)
    end

    for amount <- [1.3, 2.5] do
      test "change in amount #{amount} field remains in amount_value", %{socket: socket} do
	amount = unquote(amount)
	assigns = %{id: 1, language: "eo"}
	{:ok, socket} = IngredientLive.update(assigns, socket)

	attrs = %{"_target" => ["amount"], "amount" => amount}

	{:noreply, socket} =
	  IngredientLive.handle_event("make-suggestion", attrs, socket)

	assert socket.assigns.amount_value == amount
      end
    end

    for unit <- ["gramo", "kulereto"] do
      test "change in unit #{unit} field remains in unit_value", %{socket: socket} do
	unit = unquote(unit)
	assigns = %{id: 1, language: "eo"}
	{:ok, socket} = IngredientLive.update(assigns, socket)

	attrs = %{"_target" => ["unit-name"], "unit-name" => unit}

	{:noreply, socket} =
	  IngredientLive.handle_event("make-suggestion", attrs, socket)

	assert socket.assigns.unit_name_value == unit
      end
    end

    for substance <- ["salo", "pipro"] do
      test "change in substance #{substance} field remains in substance_value", %{socket: socket} do
	substance = unquote(substance)
	assigns = %{id: 1, language: "eo"}
	{:ok, socket} = IngredientLive.update(assigns, socket)

	attrs = %{"_target" => ["substance-name"], "substance-name" => substance}

	{:noreply, socket} =
	  IngredientLive.handle_event("make-suggestion", attrs, socket)

	assert socket.assigns.substance_name_value == substance
      end
    end

    test "submit event salo", %{socket: socket} do
      assigns = %{id: 1, language: "eo"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{
	"amount" => "1.3",
	"unit-name" => "gramo",
	"substance-name" => "salo",
	"substance-kind" => "vegan",
	"number" => "ingredient-3"
      }

      {:noreply, _socket} =
	IngredientLive.handle_event("submit", attrs, socket)

      amount = Decimal.new("1.3")

      assert_received({
	:phoenix, :send_update,
	{
	  ReceptarWeb.IngredientsLive,
	  "ingredients",
	  %{
	    id: "ingredients",
	    submit_ingredient: %{
	      amount: ^amount,
	      unit: %{name: "gramo"},
	      substance: %{
		name: "salo",
		kind: :vegan
	      },
	      number: 3
	    }
	  }
	}
      })
    end

    test "submit event ŝafida viando", %{socket: socket} do
      assigns = %{id: 1, language: "eo"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{
	"amount" => "1",
	"unit-name" => "kilogramo",
	"substance-name" => "ŝafida viando",
	"substance-kind" => "meat",
	"number" => "ingredient-2"
      }

      {:noreply, _socket} =
	IngredientLive.handle_event("submit", attrs, socket)

      amount = Decimal.new("1")

      assert_received({
	:phoenix, :send_update,
	{
	  ReceptarWeb.IngredientsLive,
	  "ingredients",
	  %{
	    id: "ingredients",
	    submit_ingredient: %{
	     amount: ^amount,
	     unit: %{name: "kilogramo"},
	     substance: %{
	       name: "ŝafida viando",
	       kind: :meat
	     },
	     number: 2
	    }
	  }
	}
      })
    end

    test "submit event ŝafa fromaĝo", %{socket: socket} do
      assigns = %{id: 1, language: "eo"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{
	"amount" => "1",
	"unit-name" => "kilogramo",
	"substance-name" => "ŝafa fromaĝo",
	"substance-kind" => "vegetarian",
	"number" => "ingredient-1"
      }

      {:noreply, _socket} =
	IngredientLive.handle_event("submit", attrs, socket)

      amount = Decimal.new("1")

      assert_received({
	:phoenix, :send_update,
	{
	  ReceptarWeb.IngredientsLive,
	  "ingredients",
	  %{
	    id: "ingredients",
	    submit_ingredient: %{
	      amount: ^amount,
	      unit: %{name: "kilogramo"},
	      substance: %{
		name: "ŝafa fromaĝo",
		kind: :vegetarian
	      },
	      number: 1
	    }
	  }
	}
      })
    end
  end

  describe "Connection state" do

    setup do
      insert_test_data()
      {:ok, %{session: %{
		 "ingredient" => some_valid_ingredient(),
		 "language" => "eo"
	      }}}
    end

    @tag :skip
    test "substance edit request without language parameter does not fail",
      %{conn: conn, session: session} do

      {:ok, _view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)
    end

    test "substance form has a form", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      form_element = element(view, "form")

      assert render(form_element) =~ ~r/phx-submit="submit"/
      assert render(form_element) =~ ~r/phx-change="make-suggestion"/
    end

    test "ingredient form has an input field named #substance-input", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      input_element = element(view, "form input#substance-input-2")

      assert render(input_element) =~~r/name="substance-name"/
      assert render(input_element) =~~r/phx-debounce="700"/
      assert render(input_element) =~~r/autocomplete="off"/
      assert render(input_element) =~~r/list="substance-suggestions-2"/
    end

    test "empty substance name input leads to no suggestions",
      %{conn: conn, session: session} do

      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      assert view |> element("datalist#substance-suggestions-2") |> has_element?()
      refute view |> element("datalist#substance-suggestions-2 option") |> has_element?()
    end

    test "substance-name input sa in eo -> options salo, sardeloj",
    %{conn: conn, session: session} do

      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      html = view
      |> element("form")
      |> render_change(%{"_target" => ["substance-name"], "substance-name" => "sa"})

      assert html =~ ~r/<option value="salo">.*<option value="sardeloj">/
    end

    test "ingredient form has an input field named #unit-input",
      %{conn: conn, session: session} do

      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      input_element = element(view, "form input#unit-input-2")

      assert render(input_element) =~~r/name="unit-name"/
      assert render(input_element) =~~r/phx-debounce="700"/
      assert render(input_element) =~~r/autocomplete="off"/
      assert render(input_element) =~~r/list="unit-suggestions-2"/
    end

    for  number <- [1, 2] do
      test "ingredient form has hidden number #{number} input field",
	%{conn: conn, session: session} do

	number = unquote(number)

	session = %{session | "ingredient" => %{session["ingredient"] | number: number}}

	{:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

	hidden_element = element(view, "form input.ingredient-number-input")

	assert render(hidden_element) =~ ~r/name="number"/
	assert render(hidden_element) =~ ~r/type="hidden"/
	assert render(hidden_element) =~ ~r/value="#{number}"/
      end
    end

    test "empty unit name input leads to all suggestions in Esperanto",
      %{conn: conn, session: session} do

      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      assert view |> element("datalist#unit-suggestions-2") |> has_element?()

      html = view
      |> element("form")
      |> render()

      assert html =~ ~r/<option value="gramo">.*<option value="kilogramo">.*<option value="kulereto">/
    end

    test "unit name 'g' input leads to suggestion 'gramo' in Esperanto",
      %{conn: conn, session: session} do

      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      html = view
      |> element("form")
      |> render_change(%{"_target" => ["unit-name"], "unit-name" => "g"})

      assert html =~ ~r/<option value="gramo">/
      refute html =~ ~r/<option value="kilogramo">.*<option value="kulereto">/
    end

    test "form has an amount input", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      input_element = element(view, "form input#amount-input-2")

      assert render(input_element) =~~r/name="amount"/
      assert render(input_element) =~~r/phx-debounce="700"/
      assert render(input_element) =~~r/autocomplete="off"/
      assert render(input_element) =~~r/type="number"/
    end

    test "form has radio buttons for substance kind", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      vegan_rb = element(view, "form .vegan-rb")
      vegetarian_rb = element(view, "form .vegetarian-rb")
      meat_rb = element(view, "form .meat-rb")

      assert render(vegan_rb) =~ ~r/value="vegan"/
      assert render(vegetarian_rb) =~ ~r/value="vegetarian"/
      assert render(meat_rb) =~ ~r/value="meat"/

      assert render(vegan_rb) =~ ~r/name="substance-kind"/
      assert render(vegetarian_rb) =~ ~r/name="substance-kind"/
      assert render(meat_rb) =~ ~r/name="substance-kind"/

      assert render(vegan_rb) =~ ~r/type="radio"/
      assert render(vegetarian_rb) =~ ~r/type="radio"/
      assert render(meat_rb) =~ ~r/type="radio"/
    end

    test "form has a submit button", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      html = view
      |> element("form button")
      |> render()

      assert html =~ ~r/type="submit"/
    end

    for selector <- [
	  "form #amount-input-1",
	  "form #substance-input-1",
	  "form #unit-input-1"]
      do

      test "by default all #{selector} is blank", %{conn: conn} do
	session = %{
	  "ingredient" => %{
	    amount: nil,
	    unit: %{name: ""},
	    substance: %{name: ""},
	    number: 1
	  },
	  "language" => "eo"
	}
	{:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

	html = view
	|> element(unquote(selector))
	|> render()

	assert html =~ ~r/value=""/
      end
    end

    for {selector, value} <- [
	  {"form #amount-input-2", "1.3"},
	  {"form #substance-input-2", "salo"},
	  {"form #unit-input-2", "gramo"}
	] do

	test "#{selector} take value from ingredient", %{conn: conn, session: session} do
	  {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

	  html = view
	  |> element(unquote(selector))
	  |> render()

	  assert html =~ ~r/value="#{unquote(value)}"/
	end
    end

    for selector <- ["form .vegan-rb", "form .vegetarian-rb", "form .meat-rb"] do
      test "by default #{selector} radio button is not checked", %{conn: conn} do
	session = %{
	  "ingredient" => %{
	    amount: nil,
	    unit: %{name: ""},
	    substance: %{name: ""},
	    number: 1
	  },
	  "language" => "eo"
	}
	{:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

	html = view
	|> element(unquote(selector))
	|> render()

	refute html =~ "checked"
      end
    end

    @tag :skip
    test "examine params", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      view
      |> element("form")
      |> render_submit(%{foo: "bar"})
    end
  end

end

defmodule ReceptarWeb.IngredientTestLiveView do
  use Phoenix.LiveView

  alias ReceptarWeb.IngredientLive

  def render(assigns) do
    ~H"<.live_component
    module={IngredientLive}
    id={@ingredient.number}
    ingredient={@ingredient}
    language={@language}
    />"
  end

  def mount(_params, session, socket) do
    %{
      "ingredient" => ingredient,
      "language" => language
    } = session
    socket =
      socket
      |> assign(ingredient: ingredient)
      |> assign(language: language)

    {:ok, socket}
  end
end
