defmodule ReceptarWeb.InstructionsLiveTest do
  import Assertions
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Phoenix.LiveViewTest
  import Phoenix.LiveView

  import Receptar.Seeder
  import Receptar.TestHelpers

  alias Receptar.Instructions
  alias ReceptarWeb.InstructionsLive

  alias ReceptarWeb.InstructionsTestLiveView

  defp create_socket() do
    %Phoenix.LiveView.Socket{}
  end

  describe "Socket state" do
    setup do
      insert_test_data()
      instructions =
	recipe_by_title("granda kino").instructions
        |> Instructions.translate("eo")

      %{
	socket: create_socket(),
	params: %{instructions: instructions, edit_instructions: [], language: "eo"},
      }
    end

    test "by default no instruction is edited", %{socket: socket, params: params} do
      {:ok, socket} = InstructionsLive.update(params, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_instructions: []}
      } = socket
    end

    test "edit-instruction 1 event", %{socket: socket, params: params} do
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "1"}, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_instructions: [1]}
      } = socket
    end

    test "edit-instruction 1 and 7 events", %{socket: socket, params: params} do
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "1"}, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "7"}, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_instructions: [7, 1]}
      } = socket
    end

    test "edit-instruction 1 and 1 events", %{socket: socket, params: params} do
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "1"}, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "1"}, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_instructions: [1]}
      } = socket
    end

    test "add non int number to instruction edit list does not fail",
      %{socket: socket, params: params} do

      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, _socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "foo"}, socket)
    end

    for {number, remaining} <- [{"1", [3]}, {"3", [1]}, {"foo", [1, 3]}] do
      @tag :skip  # multiple simultaneous edits will be handled in the future
      test "cancel-edit-instruction-event #{number}", %{socket: socket, params: params} do
	params = %{params | edit_instructions: [1, 3]}
	{:ok, socket} = InstructionsLive.update(params, socket)

	translatable = %{"number" => unquote(number)}

	{:ok, socket} =
	  InstructionsLive.update(%{cancel_translation: %{translatable: translatable}}, socket)

	assert socket.assigns.edit_instructions == unquote(remaining)
      end
    end

    for number <- [1, 2] do
      test "update_translation of existing #{number} event", %{socket: socket, params: params} do
	{:ok, socket} = InstructionsLive.update(params, socket)
	number = unquote(number)

	instruction = Enum.fetch!(params.instructions, number-1)
	translations_updated = [%{language: "eo", content: "ŝanĝita"}]

	{:ok, socket} =
	  InstructionsLive.update(
	    %{
	      update_translations: %{
		translatable: instruction,
		translations: translations_updated
	      }
	    },
	    socket |> assign(edit_instructions: [1, 2])
	  )

	assert_received(
	  {
	    :update_translations,
	    %{
	      translatable: ^instruction,
	      translations: ^translations_updated
	    }
	  }
	)

	refute number in socket.assigns.edit_instructions
      end
    end

    for {language, content, translations} <- [
	  {"eo", "nova", [%{language: "eo", content: "nova"}]},
	  {"de", "neu", [%{language: "de", content: "neu"}]},
	  {
	    "eo", "ankaŭ nova", [
	      %{language: "eo", content: "ankaŭ nova"}, %{language: "de", content: "auch neu"}
	    ]
	  }
	] do
	test "update_translation of new first instruction #{content}", %{socket: socket, params: params} do
	  language = unquote(language)
	  content = unquote(content)
	  translations_updated = unquote(Macro.escape(translations))
	  params = %{params | instructions: []}
	  params = %{params | language: language}

	  {:ok, socket} = InstructionsLive.update(params, socket)

	  {:noreply, socket} =
	    InstructionsLive.handle_event("append-instruction", %{}, socket)

	  {:ok, _socket} =
	    InstructionsLive.update(
	      %{
		update_translations: %{
		  translatable: %{content: "", number: 1, translations: []},
		  translations: translations_updated
		}
	      },
	      socket |> assign(edit_instructions: [1])
	    )

	  refute_received({:update_translations, %{}})

	  expected_instructions = [
	    %{number: 1, content: content, translations: translations_updated}
	  ]

	  assert_received(
	    {
	      :update_instructions,
	      %{
		instructions: ^expected_instructions
	      }
	    }
	  )
	end
    end

    test "update_translation of appended instruction", %{socket: socket, params: params} do
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("append-instruction", %{}, socket)

      translations_updated = [%{language: "eo", content: "nova"}]

      {:ok, _socket} =
	InstructionsLive.update(
	  %{
	    update_translations: %{
	      translatable: %{content: "", number: 3, translations: []},
	      translations: translations_updated
	    }
	  },
	  socket
	)

      assert_received({:update_instructions, %{instructions: instructions}})

      instruction_3 = Enum.find(instructions, & &1.number == 3)
      assert instruction_3.content == "nova"
    end

    for {recipe_name} <- [{"granda kino"}, {"sukera bulko"}] do
      test "append instruction to event #{recipe_name}", %{socket: socket} do
	recipe = recipe_by_title(unquote(recipe_name))

	params = %{instructions: recipe.instructions, edit_instructions: [], language: "eo"}
	{:ok, socket} = InstructionsLive.update(params, socket)

	original_instructions = Instructions.translate(recipe.instructions, "eo")

	expected_instruction_number = length(original_instructions) + 1

	{:noreply, socket} =
	  InstructionsLive.handle_event("append-instruction", %{}, socket)

	%{assigns: %{instructions: instructions}} = socket

	assert [
	  %{
	    number: ^expected_instruction_number,
	    content: ""
	  } | tail] = Enum.reverse(instructions)

	assert_lists_equal Enum.map(tail, & &1.id), Enum.map(original_instructions, & &1.id)

	instructions = Enum.sort(instructions, & &1.number < &2.number)

	assert socket.assigns.instructions == instructions

	assert %Phoenix.LiveView.Socket{
	  assigns: %{edit_instructions: [^expected_instruction_number]}
	} = socket
      end
    end

    test "cancel after append", %{socket: socket, params: params} do
      params = %{params | instructions: []}
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("append-instruction", %{}, socket)

      {:ok, socket} =
	InstructionsLive.update(%{cancel_translation: %{number: 1}}, socket)

      assert socket.assigns.instructions == []
    end

    test "cancel after two appends", %{socket: socket, params: params} do
      params = %{params | instructions: []}

      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("append-instruction", %{}, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("append-instruction", %{}, socket)

      {:ok, socket} =
	InstructionsLive.update(%{cancel_translation: %{number: 2}}, socket)

      assert [%{number: 1}] = socket.assigns.instructions

      {:ok, socket} =
	InstructionsLive.update(%{cancel_translation: %{number: 1}}, socket)

      assert socket.assigns.instructions == []
    end

    test "existing instruction remains after canceled edit", %{socket: socket, params: params} do
      {:ok, socket} = InstructionsLive.update(params, socket)

      original_instructions = socket.assigns.instructions

      {:noreply, socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "1"}, socket)

      {:ok, socket} =
	InstructionsLive.update(%{cancel_translation: %{number: 1}}, socket)

      assert socket.assigns.instructions == original_instructions
      assert socket.assigns.edit_instructions == []
    end

    for {number, number_string, eis, expected_eis} <- [
	  {1, "1", [], []}, {2, "2", [], []}, {2, "2", [1], [1]}, {1, "1", [1, 2], [2]}
	] do
      test "delete instruction number #{number} #{eis}", %{socket: socket, params: params} do
	edit_instructions = unquote(eis)
	expected_edit_instructions = unquote(expected_eis)
	number = unquote(number)
	number_string = unquote(number_string)

	params = %{params | edit_instructions: edit_instructions}
	{:ok, socket} = InstructionsLive.update(params, socket)

	expected_instructions =
	  params.instructions
	  |> Enum.filter(& &1.number != number)
	  |> Enum.map(& %{&1 | number: 1})

	{:noreply, _socket} =
	  InstructionsLive.handle_event("delete-instruction", %{"number" => number_string}, socket)

	assert_received(
	  {
	    :update_instructions,
	    %{
	      instructions: ^expected_instructions,
	      edit_instructions: ^expected_edit_instructions
	    }
	  }
	)
      end
    end

    test "insert instruction 1", %{socket: socket, params: params} do
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("insert-instruction", %{"number" => "1"}, socket)

      assert [
	%{content: "", number: 1},
	%{content: "kuiri nudelojn", number: 2},
	%{content: "aldoni tinuson", number: 3}
      ] = socket.assigns.instructions

      assert socket.assigns.edit_instructions == [1]
      assert socket.assigns.new_instructions == [1]
    end

    test "insert instruction 2", %{socket: socket, params: params} do
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("insert-instruction", %{"number" => "2"}, socket)

      assert [
	%{content: "kuiri nudelojn", number: 1},
	%{content: "", number: 2},
	%{content: "aldoni tinuson", number: 3}
      ] = socket.assigns.instructions

      assert socket.assigns.edit_instructions == [2]
      assert socket.assigns.new_instructions == [2]
    end

    test "insert instruction 1 and 2", %{socket: socket, params: params} do
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("insert-instruction", %{"number" => "2"}, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("insert-instruction", %{"number" => "1"}, socket)

      assert [
	%{content: "", number: 1, translations: []},
	%{content: "kuiri nudelojn", number: 2},
	%{content: "", number: 3, translations: []},
	%{content: "aldoni tinuson", number: 4}
      ] = socket.assigns.instructions

      assert socket.assigns.edit_instructions == [1, 3]
      assert socket.assigns.new_instructions == [1, 3]
    end

    test "push instruction 1", %{socket: socket, params: params} do
      {:ok, socket} = InstructionsLive.update(params, socket)

      InstructionsLive.handle_event("push-instruction", %{"number" => "1"}, socket)

      assert_received(
	  {
	    :update_instructions,
	    %{
	      instructions: [
		%{number: 1, content: "aldoni tinuson"},
		%{number: 2, content: "kuiri nudelojn"},
	      ],
	    }
	  }
	)
    end

    test "pull instruction 2", %{socket: socket, params: params} do
      {:ok, socket} = InstructionsLive.update(params, socket)

      InstructionsLive.handle_event("pull-instruction", %{"number" => "2"}, socket)

      assert_received(
	  {
	    :update_instructions,
	    %{
	      instructions: [
		%{number: 1, content: "aldoni tinuson"},
		%{number: 2, content: "kuiri nudelojn"},
	      ],
	    }
	  }
	)
    end
end

  describe "Connection state" do
    setup do
      insert_test_data()
      %{instruction: %{
	   content: "foo",
	   number: 1,
	   translations: [
	     %{language: "eo", content: "foo"},
	     %{language: "de", content: "bar"}]
	}, language: "eo"}
    end

    test "initial view does not have form elements",
      %{conn: conn, instruction: instruction, language: language} do

      session = %{"instructions" => [instruction], "language" => language}
      {:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      refute view |> has_element?("form")
    end

    test "append first instruction", %{conn: conn} do
      session = %{"instructions" => [], "language" => "eo"}
      {:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      refute view |> has_element?("form#edit-translation-instruction-1")

      view
      |> element("a#append-instruction")
      |> render_click()

      assert view |> has_element?("form#edit-translation-instruction-1")
    end

    test "append second instruction", %{conn: conn, instruction: instruction} do
      session = %{"instructions" => [instruction], "language" => "eo"}
      {:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      html = view
      |> element("#instruction-1")
      |> render()

      assert html =~ ~r/phx-value-number="1"/
      refute view |> has_element?("form#edit-translation-instruction-2")

      html = view
      |> element("a#append-instruction")
      |> render_click()
      |> strip_html_code

      assert view |> has_element?("form#edit-translation-instruction-2")
      assert html =~ ~r/id="delete-instruction-2"[^>]*phx-value-number="2"/
    end

    test "append third instruction", %{conn: conn, instruction: instruction} do
      session = %{"instructions" => [instruction, %{instruction | number: 2}], "language" => "eo"}
      {:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      html = view
      |> element("#instruction-2")
      |> render()

      assert html =~ ~r/phx-value-number="2"/
      refute view |> has_element?("form#edit-translation-instruction-3")

      html = view
      |> element("a#append-instruction")
      |> render_click()
      |> strip_html_code

      assert view |> has_element?("form#edit-translation-instruction-3")
      assert html =~ ~r/id="delete-instruction-3"[^>]*phx-value-number="3"/
    end

    for number <- [1, 2] do
      test "edit instruction #{number}", %{conn: conn, instruction: instruction} do
	number = unquote(number)
	session = %{
	  "instructions" =>
	  [
	    %{instruction | number: 1},
	    %{instruction | number: 2}
	  ],
	  "edit_instructions" => [],
	  "language" => "eo"
	}
	{:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

	html = view
	|> element("#instruction-#{number}")
	|> render()

	assert html =~ ~r/phx-value-number="#{number}"/

	view
	|> element("#instruction-#{number}")
	|> render_click()
      end
    end

    for number <- [1, 2] do
      test "cancel edit instruction #{number}", %{conn: conn, instruction: instruction} do
	number = unquote(number)

	session = %{
	  "instructions" =>
	  [
	    %{instruction | number: 1},
	    %{instruction | number: 2},
	    %{instruction | number: 3},
	  ],
	  "edit_instructions" => [number],
	  "language" => "eo"
	}

	{:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

	view
	|> element("form button.cancel")
	|> render_click()
      end
    end

    test "delete instruction", %{conn: conn, instruction: instruction} do
      session = %{"instructions" => [instruction], "edit_instructions" => [],  "language" => "eo"}
      {:ok, view, html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      assert html =~ ~r/id="instruction-1"/

      view
      |> element("#delete-instruction-1")
      |> render_click()
    end

    for number <- [1, 2] do
      test "insert instruction #{number}", %{conn: conn, instruction: instruction} do
	number = unquote(number)
	session = %{"instructions" =>
		     [
		       %{instruction | number: 1},
		       %{instruction | number: 2}
		     ],
		    "edit_instructions" => [],
		    "language" => "eo"
		   }
	{:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

	html = view
	|> element("#insert-instruction-#{number}")
	|> render()

	assert html =~ ~r/phx-value-number="#{number}"/

	view
	|> element("#instruction-#{number}")
	|> render_click()
      end
    end

    test "submit instruction", %{conn: conn, instruction: instruction} do
      session = %{"instructions" => [instruction], "edit_instructions" => [1],  "language" => "eo"}
      {:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      view
      |> element("form#edit-translation-instruction-1")
      |> render_submit()
    end

    test "edit-instruction form has textarea", %{conn: conn, instruction: instruction} do
      session = %{"instructions" => [instruction], "edit_instructions" => [1],  "language" => "eo"}
      {:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      assert view
      |> has_element?("form#edit-translation-instruction-1 textarea")
    end
  end
end


defmodule ReceptarWeb.InstructionsTestLiveView do
  use Phoenix.LiveView

  alias ReceptarWeb.InstructionsLive

  def render(assigns) do
    ~H"<.live_component
    module={InstructionsLive}
    id=\"instructions\"
    instructions={@instructions}
    edit_instructions={@edit_instructions}
    language={@language}
    />"
  end

  def mount(_parmas, session, socket) do
    %{"instructions" => instructions, "language" => language} = session
    edit_instructions = case session do
			  %{"edit_instructions" => eis} -> eis
			  _ -> []
			end

    {:ok,
     socket
     |> assign(instructions: instructions)
     |> assign(edit_instructions: edit_instructions)
     |> assign(language: language)
    }
  end
end
