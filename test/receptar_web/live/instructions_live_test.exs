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
    %{socket: %Phoenix.LiveView.Socket{}}
  end

  describe "Socket state" do
    setup do
      insert_test_data()
      create_socket()
    end

    test "by default no instruction is edited", %{socket: socket} do
      instructions =
	recipe_by_title("granda kino").instructions
	|> Instructions.translate("eo")

      params = %{instructions: instructions, edit_instructions: []}
      {:ok, socket} = InstructionsLive.update(params, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_instructions: []}
      } = socket
    end

    test "edit-instruction 1 event", %{socket: socket} do
      instructions =
	recipe_by_title("granda kino").instructions
	|> Instructions.translate("eo")

      params = %{instructions: instructions, edit_instructions: []}
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "1"}, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_instructions: [1]}
      } = socket
    end

    test "edit-instruction 1 and 7 events", %{socket: socket} do
      instructions =
	recipe_by_title("granda kino").instructions
	|> Instructions.translate("eo")

      params = %{instructions: instructions, edit_instructions: []}
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "1"}, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "7"}, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_instructions: [7, 1]}
      } = socket
    end

    test "edit-instruction 1 and 1 events", %{socket: socket} do
      instructions =
	recipe_by_title("granda kino").instructions
	|> Instructions.translate("eo")

      params = %{instructions: instructions, edit_instructions: []}
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "1"}, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "1"}, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{edit_instructions: [1]}
      } = socket
    end

    test "add non int number to instruction edit list does not fail", %{socket: socket} do
      instructions =
	recipe_by_title("granda kino").instructions
	|> Instructions.translate("eo")

      params = %{instructions: instructions, edit_instructions: []}
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, _socket} =
	InstructionsLive.handle_event("edit-instruction", %{"number" => "foo"}, socket)
    end

    for {number, remaining} <- [{"1", [3]}, {"3", [1]}, {"foo", [1, 3]}] do
      test "cancel-edit-instruction-event #{number}", %{socket: socket} do
	instructions =
	  recipe_by_title("granda kino").instructions
	|> Instructions.translate("eo")

	params = %{instructions: instructions, edit_instructions: [1, 3]}
	{:ok, socket} = InstructionsLive.update(params, socket)

	attrs = %{"number" => unquote(number)}

	{:noreply, socket} =
	  InstructionsLive.handle_event("cancel-edit-instruction", attrs, socket)

	assert socket.assigns.edit_instructions == unquote(remaining)
      end
    end

    test "submit-instruction-1 event", %{socket: socket} do
      instructions =
	recipe_by_title("granda kino").instructions
	|> Instructions.translate("eo")

      params = %{instructions: instructions, edit_instructions: []}
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, _socket} =
	InstructionsLive.handle_event(
	  "submit-instruction-1",
	  %{"instruction-content" => "preparado"},
	  socket |> assign(edit_instructions: [1, 2])
	)

      assert_received({
	:update_instructions,
	%{
	  instructions: [%{content: "preparado", number: 1}, _],
	  edit_instructions: [2]
	}
      })
    end

    test "submit-instruction-2 event", %{socket: socket} do
      instructions =
	recipe_by_title("granda kino").instructions
	|> Instructions.translate("eo")

      params = %{instructions: instructions, edit_instructions: []}
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, _socket} =
	InstructionsLive.handle_event(
	  "submit-instruction-2",
	  %{"instruction-content" => "finfarado"},
	  socket |> assign(edit_instructions: [2])
	)

      assert_received({
	:update_instructions,
	%{
	  instructions: [_, %{content: "finfarado", number: 2}],
	  edit_instructions: []
	}
      })
    end

    for {recipe_name} <- [{"granda kino"}, {"sukera bulko"}] do
      test "append instruction to event #{recipe_name}", %{socket: socket} do
	recipe = recipe_by_title(unquote(recipe_name))

	params = %{instructions: recipe.instructions, edit_instructions: []}
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

    test "cancel after append", %{socket: socket} do
      params = %{instructions: [], edit_instructions: []}

      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("append-instruction", %{}, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("cancel-edit-instruction", %{"number" => "1"}, socket)

      assert socket.assigns.instructions == []
    end

    test "cancel after two appends", %{socket: socket} do
      params = %{instructions: [], edit_instructions: []}

      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("append-instruction", %{}, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("append-instruction", %{}, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("cancel-edit-instruction", %{"number" => "2"}, socket)

      assert [%{number: 1}] = socket.assigns.instructions

      {:noreply, socket} =
	InstructionsLive.handle_event("cancel-edit-instruction", %{"number" => "1"}, socket)

      assert socket.assigns.instructions == []
    end

    for {number, number_string, eis, expected_eis} <- [
	  {1, "1", [], []}, {2, "2", [], []}, {2, "2", [1], [1]}, {1, "1", [1, 2], [2]}
	] do
      test "delete instruction number #{number} #{eis}", %{socket: socket} do
	edit_instructions = unquote(eis)
	expected_edit_instructions = unquote(expected_eis)
	number = unquote(number)
	number_string = unquote(number_string)

	instructions =
	  recipe_by_title("granda kino").instructions
	  |> Instructions.translate("eo")

	params = %{instructions: instructions, edit_instructions: edit_instructions}
	{:ok, socket} = InstructionsLive.update(params, socket)

	expected_instructions =
	  instructions
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

    test "insert instruction 1", %{socket: socket} do
      instructions =
	recipe_by_title("granda kino").instructions
        |> Instructions.translate("eo")

      params = %{instructions: instructions, edit_instructions: []}
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

    test "insert instruction 2", %{socket: socket} do
      instructions =
	recipe_by_title("granda kino").instructions
        |> Instructions.translate("eo")

      params = %{instructions: instructions, edit_instructions: []}
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

    test "insert instruction 1 and 2", %{socket: socket} do
      instructions =
	recipe_by_title("granda kino").instructions
        |> Instructions.translate("eo")

      params = %{instructions: instructions, edit_instructions: []}
      {:ok, socket} = InstructionsLive.update(params, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("insert-instruction", %{"number" => "2"}, socket)

      {:noreply, socket} =
	InstructionsLive.handle_event("insert-instruction", %{"number" => "1"}, socket)

      assert [
	%{content: "", number: 1},
	%{content: "kuiri nudelojn", number: 2},
	%{content: "", number: 3},
	%{content: "aldoni tinuson", number: 4}
      ] = socket.assigns.instructions

      assert socket.assigns.edit_instructions == [1, 3]
      assert socket.assigns.new_instructions == [1, 3]
    end

    test "push instruction 1", %{socket: socket} do
      instructions =
	recipe_by_title("granda kino").instructions
        |> Instructions.translate("eo")

      params = %{instructions: instructions, edit_instructions: []}
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

    test "pull instruction 2", %{socket: socket} do
      instructions =
	recipe_by_title("granda kino").instructions
        |> Instructions.translate("eo")

      params = %{instructions: instructions, edit_instructions: []}
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
      %{instruction: %{content: "foo", number: 1}}
    end

    test "initial view does not have form elements",
      %{conn: conn, instruction: instruction} do

      session = %{"instructions" => [instruction]}
      {:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      refute view |> has_element?("form")
    end

    test "append first instruction", %{conn: conn} do
      session = %{"instructions" => []}
      {:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      html = view
      |> element("a#append-instruction")
      |> render_click()
      |> strip_html_code

      assert html =~ ~r/<form phx-submit="submit-instruction-1"/
      assert html =~ ~r/<button.*phx-click="cancel-edit-instruction"/
      assert html =~ ~r/<button.*phx-value-number="1"/
      assert html =~ ~r/<button.*type="button"/
    end

    test "append second instruction", %{conn: conn, instruction: instruction} do
      session = %{"instructions" => [instruction]}
      {:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      html = view
      |> element("#instruction-1")
      |> render()

      assert html =~ ~r/phx-value-number="1"/

      html = view
      |> element("a#append-instruction")
      |> render_click()
      |> strip_html_code

      assert html =~ ~r/<form phx-submit="submit-instruction-2"/
      assert html =~ ~r/<button.*phx-click="cancel-edit-instruction"/
      assert html =~ ~r/<button.*phx-value-number="2"/
      assert html =~ ~r/<button.*type="button"/
      assert html =~ ~r/id="delete-instruction-2"[^>]*phx-value-number="2"/
    end

    test "append third instruction", %{conn: conn, instruction: instruction} do
      session = %{"instructions" => [instruction, %{instruction | number: 2}]}
      {:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      html = view
      |> element("#instruction-2")
      |> render()

      assert html =~ ~r/phx-value-number="2"/

      html = view
      |> element("a#append-instruction")
      |> render_click()
      |> strip_html_code

      assert html =~ ~r/<form phx-submit="submit-instruction-3"/
      assert html =~ ~r/<button.*phx-click="cancel-edit-instruction"/
      assert html =~ ~r/<button.*phx-value-number="3"/
      assert html =~ ~r/<button.*type="button"/
      assert html =~ ~r/id="delete-instruction-3"[^>]*phx-value-number="3"/
    end

    for number <- [1, 2] do
      test "edit instruction #{number}", %{conn: conn, instruction: instruction} do
	number = unquote(number)
	session = %{"instructions" => [
		     %{instruction | number: 1},
		     %{instruction | number: 2}
		   ], "edit_instructions" => []}
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
	  "instructions" => [
	  %{instruction | number: 1},
	  %{instruction | number: 2},
	  %{instruction | number: 3},
	],
	  "edit_instructions" => [number]}

	{:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

	cancel_button = element(view, "form button.cancel-button")
	html = render(cancel_button)

	render_click(cancel_button)

	assert html =~ ~r/phx-value-number="#{number}"/
      end
    end

    test "delete instruction", %{conn: conn, instruction: instruction} do
      session = %{"instructions" => [instruction], "edit_instructions" => []}
      {:ok, view, html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      assert html =~ ~r/id="instruction-1"/

      view
      |> element("#delete-instruction-1")
      |> render_click()
    end

    for number <- [1, 2] do
      test "insert instruction #{number}", %{conn: conn, instruction: instruction} do
	number = unquote(number)
	session = %{"instructions" => [
		     %{instruction | number: 1},
		     %{instruction | number: 2}
		   ], "edit_instructions" => []}
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
      session = %{"instructions" => [instruction], "edit_instructions" => [1]}
      {:ok, view, _html} = live_isolated(conn, InstructionsTestLiveView, session: session)

      view
      |> element("form")
      |> render_submit()
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
    />"
  end

  def mount(_parmas, session, socket) do
    %{"instructions" => instructions} = session
    edit_instructions = case session do
			  %{"edit_instructions" => eis} -> eis
			  _ -> []
			end

    {:ok,
     socket
     |> assign(instructions: instructions)
     |> assign(edit_instructions: edit_instructions)
    }
  end
end
