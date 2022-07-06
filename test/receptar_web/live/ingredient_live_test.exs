defmodule ReceptarWeb.IngredientLiveTest do
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Receptar.Seeder
  import Phoenix.LiveViewTest
  import Phoenix.LiveView.Helpers

  import Receptar.TestHelpers
  alias Receptar.Substances.Substance
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
	IngredientLive.handle_event("change-event", attrs, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{substance_suggestions: []}
      } = socket
    end

    test "substance prefix 'sa' in Esperanto suggests 'salo", %{socket: socket} do
      assigns = %{id: 1, language: "eo"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{"_target" => ["substance-name"], "substance-name" => "sa"}

      {:noreply, socket} =
	IngredientLive.handle_event("change-event", attrs, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{substance_suggestions: ["salo", "sardeloj"]}
      } = socket
    end

    test "substance prefix 'sa' in German suggests 'Salz'", %{socket: socket} do
      assigns = %{id: 1, language: "de"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{"_target" => ["substance-name"], "substance-name" => "sa"}

      {:noreply, socket} =
	IngredientLive.handle_event("change-event", attrs, socket)

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
	IngredientLive.handle_event("change-event", attrs, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{unit_suggestions: ["gramo"]}
      } = socket
    end

    test "unit prefix 'g' in German suggests 'Gramm'", %{socket: socket} do
      assigns = %{id: 1, language: "de"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{"_target" => ["unit-name"], "unit-name" => "g"}

      {:noreply, socket} =
	IngredientLive.handle_event("change-event", attrs, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{unit_suggestions: ["Gramm"]}
      } = socket
    end

    test "change in amount field does not crash", %{socket: socket} do
      assigns = %{id: 1, language: "eo"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      attrs = %{"_target" => ["amount"]}

      {:noreply, _socket} =
	IngredientLive.handle_event("change-event", attrs, socket)
    end

    for amount <- [1.3, 2.5] do
      test "change in amount #{amount} field remains in amount_value", %{socket: socket} do
	amount = unquote(amount)
	assigns = %{id: 1, language: "eo"}
	{:ok, socket} = IngredientLive.update(assigns, socket)

	attrs = %{"_target" => ["amount"], "amount" => amount}

	{:noreply, socket} =
	  IngredientLive.handle_event("change-event", attrs, socket)

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
	  IngredientLive.handle_event("change-event", attrs, socket)

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
	  IngredientLive.handle_event("change-event", attrs, socket)

	assert socket.assigns.substance_name_value == substance
      end
    end

    test "change in kind radio buttons remains in substance_kind_value", %{socket: socket} do
	assigns = %{id: 1, language: "eo"}
	{:ok, socket} = IngredientLive.update(assigns, socket)

	attrs = %{"_target" => ["substance-kind"], "substance-kind" => "vegan"}

	{:noreply, socket} =
	  IngredientLive.handle_event("change-event", attrs, socket)

	assert socket.assigns.substance_kind_value == :vegan
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

    for number <- [1, 2] do
      test "submit event ŝafa fromaĝo #{number}", %{socket: socket} do
	number = unquote(number)
	assigns = %{id: 1, language: "eo"}
	{:ok, socket} = IngredientLive.update(assigns, socket)

	attrs = %{
	  "amount" => "#{number}",
	  "unit-name" => "kilogramo",
	  "substance-name" => "ŝafa fromaĝo",
	  "substance-kind" => "vegetarian",
	  "number" => "ingredient-#{number}"
	}

	{:noreply, _socket} =
	  IngredientLive.handle_event("submit", attrs, socket)

	amount = Decimal.new("#{number}")

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
		number: ^number
	      }
	    }
	  }
	    })
      end

      test "submit cancel edit #{number}", %{socket: socket} do
	number = unquote(number)
	assigns = %{id: 1, language: "eo"}
	{:ok, socket} = IngredientLive.update(assigns, socket)

	{:noreply, _socket} =
	  IngredientLive.handle_event("cancel", %{"number" => "#{number}"}, socket)

	assert_received({
	  :phoenix, :send_update,
	  {
	    ReceptarWeb.IngredientsLive,
	    "ingredients",
	    %{
	      id: "ingredients",
	      cancel: ^number
	    }
	  }
	})
      end
    end

    for {num, perm} <- permutation_of([
	  %{"_target" => ["substance-kind"], "substance-kind" => "vegan"},
	  %{"_target" => ["substance-name"], "substance-name" => "foo"},
	  %{"_target" => ["amount"], "amount" => "1.3"},
	  %{"_target" => ["unit-name"], "unit-name" => "litro"}
	]) |> Enum.with_index(fn el, num -> {num, el} end) do
	test "enabling submit button #{num}", %{socket: socket} do
	  ingredient = %{
	    amount: nil,
	    unit: %{name: ""},
	    substance: %Substance{name: "", kind: nil},
	    number: 1
	  }

	  assigns = %{id: 1, ingredient: ingredient, language: "eo"}
	  {:ok, socket} = IngredientLive.update(assigns, socket)

	  socket = unquote(Macro.escape(perm))
	  |> Enum.map_reduce(false, fn
	    %{"substance-kind" => _} = change, false -> {change, true}
	    %{"substance-name" => _}, true -> {%{"_target" => ["substance-name"], "substance-name" => "salo"}, true}
	    change, acc -> {change, acc}
	  end)
	  |> then(fn {changes, _} -> changes end)
	  |> Enum.reduce(socket, fn change, socket ->
	    assert socket.assigns.submit_disabled
	    {:noreply, socket} = IngredientLive.handle_event("change-event", change, socket)
 	    socket
	  end)

	  refute socket.assigns.submit_disabled
	end
    end

    test "default translate_substance default false", %{socket: socket} do
      assigns = %{id: 1, language: "eo"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      refute socket.assigns.translate_substance
    end

    test "default translate_substance set true", %{socket: socket} do
      assigns = %{id: 1, language: "eo"}
      {:ok, socket} = IngredientLive.update(assigns, socket)

      {:noreply, socket}
        = IngredientLive.handle_event("translate-substance", %{}, socket)

      assert socket.assigns.translate_substance
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

    test "substance edit request without language parameter does not fail",
      %{conn: conn, session: session} do

      {:ok, _view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)
    end

    test "substance form has a form", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      form_element = element(view, "form")

      assert render(form_element) =~ ~r/phx-submit="submit"/
      assert render(form_element) =~ ~r/phx-change="change-event"/
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

      test "form #{number} has a cancel button", %{conn: conn, session: session} do
	number = unquote(number)
	session = %{session | "ingredient" => %{session["ingredient"] | number: number}}

	{:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

	html = view
	|> element("form button.cancel-button")
	|> render()

	assert html =~ ~r/type="button"/
	assert html =~ ~r/phx-click="cancel"/
	assert html =~ ~r/phx-value-number="#{number}"/
      end

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

      assert render(input_element) =~ ~r/name="amount"/
      assert render(input_element) =~ ~r/phx-debounce="700"/
      assert render(input_element) =~ ~r/autocomplete="off"/
      assert render(input_element) =~ ~r/type="number"/
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
      |> element("form button.submit-button")
      |> render()

      assert html =~ ~r/type="submit"/
    end

    test "click cancel button", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      view
      |> element("form button.cancel-button")
      |> render_click()
    end

    for selector <- [
	  "form input[name=\"amount\"][type=\"number\"][step=\"0.1\"][value=\"\"]",
	  "form input[name=\"substance-name\"][value=\"\"]",
	  "form input[name=\"unit-name\"][value=\"\"]"
	] do

      test "by default all #{selector} is blank", %{conn: conn} do
	session = %{
	  "ingredient" => %{
	    amount: nil,
	    unit: %{name: ""},
	    substance: %Substance{name: ""},
	    number: 1
	  },
	  "language" => "eo"
	}
	{:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

	assert view |> has_element?(unquote(selector))
      end
    end

    for selector <- [
	  "form input[name=\"amount\"][type=\"number\"][step=\"0.1\"][value=\"1.3\"]",
	  "form input[name=\"substance-name\"][value=\"salo\"]",
	  "form input[name=\"unit-name\"][value=\"gramo\"]",
	] do

	test "#{selector} take value from ingredient", %{conn: conn, session: session} do
	  {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

	  assert view |> has_element?(unquote(selector))
	end
    end

    for selector <- ["form .vegan-rb", "form .vegetarian-rb", "form .meat-rb"] do
      test "by default #{selector} radio button is not checked", %{conn: conn} do
	session = %{
	  "ingredient" => %{
	    amount: nil,
	    unit: %{name: ""},
	    substance: %Substance{},
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

    for kind <- [:vegan, :vegetarian, :meat] do
      test "#{kind} substance has vegan radio button ticked", %{conn: conn} do
	kind = unquote(kind)
	session = %{
	  "ingredient" => %{
	    amount: nil,
	    unit: %{name: ""},
	    substance: %Substance{name: "", kind: kind},
	    number: 1
	  },
	  "language" => "eo"
	}

	{:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

	assert view |> element("input.#{kind}-rb") |> render() =~ ~r/checked="checked"/
      end

      test "check #{kind} and then type into unit-name", %{conn: conn} do
	kind = unquote(kind)
	session = %{
	  "ingredient" => %{
	    amount: nil,
	    unit: %{name: ""},
	    substance: %Substance{name: ""},
	    number: 1
	  },
	  "language" => "eo"
	}

	{:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

	refute view |> element("input.#{kind}-rb") |> render() =~ ~r/checked="checked"/

	view
	|> element("form")
	|> render_change(%{"_target" => "substance-kind", "substance-kind" => "#{kind}"})

	view
	|> element("form")
	|> render_change(%{"_target" => "unit-name", "unit-name" => "foo"})

	assert view |> element("input.#{kind}-rb") |> render() =~ ~r/checked="checked"/
      end
    end

    for {kind, substance_name} <- [{:vegan, "salo"}, {:vegetarian, "lakto"}, {:meat, "tinuso"}] do
      test "#{substance_name} typed -> #{kind} checked", %{conn: conn} do
	kind = unquote(kind)
	name = unquote(substance_name)
	session = %{
	  "ingredient" => %{
	    amount: nil,
	    unit: %{name: ""},
	    substance: %Substance{name: ""},
	    number: 1
	  },
	  "language" => "eo"
	}

	{:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

	refute view |> element("input.#{kind}-rb") |> render() =~ ~r/checked="checked"/

	view
	|> element("form")
	|> render_change(%{"_target" => "substance-name", "substance-name" => name})

	assert view |> element("input.#{kind}-rb") |> render() =~ ~r/checked="checked"/
      end
    end

    test "vegan substance has vegetarian radio button unticked", %{conn: conn} do
      session = %{
	"ingredient" => %{
	  amount: nil,
	  unit: %{name: ""},
	  substance: %Substance{name: "", kind: :vegan},
	  number: 1
	},
	"language" => "eo"
      }

      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      refute view |> element("input.vegetarian-rb") |> render() =~ "checked"
    end

    test "test submit button disabled for new ingredient", %{conn: conn} do
      session = %{
	"ingredient" => %{
	  amount: nil,
	  unit: %{name: ""},
	  substance: %Substance{name: "", kind: :vegan},
	  number: 1
	},
	"language" => "eo"
      }

      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      html = view
      |> element("button.submit-button")
      |> render()

      assert html =~ ~r/disabled/
    end

    test "test submit button enabled for full ingredient", %{conn: conn} do
      session = %{
	"ingredient" => %{
	  amount: Decimal.new("1.0"),
	  unit: %{name: "litro"},
	  substance: %Substance{name: "vino", kind: :vegan},
	  number: 1
	},
	"language" => "eo"
      }

      {:ok, view, _html} = live_isolated(conn, IngredientTestLiveView, session: session)

      html = view
      |> element("button.submit-button")
      |> render()

      refute html =~ ~r/disabled/
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
