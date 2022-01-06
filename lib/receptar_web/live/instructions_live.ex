defmodule ReceptarWeb.InstructionsLive do
  use ReceptarWeb, :live_component

  alias Receptar.Orderables
  alias ReceptarWeb.Helpers

  def update(params, socket) do
    socket = socket
    |> assign(language: Helpers.determine_language(params))
    |> assign(instructions: params.instructions)
    |> assign(edit_instructions: params.edit_instructions)
    |> assign(new_instructions: [])
    #|> IO.inspect(label: "update")

    {:ok, socket}
  end

  def handle_event("edit-instruction", %{"number" => number}, socket) do
    edit_list = maybe_add_to_list(number, socket.assigns.edit_instructions)
    {:noreply, socket |> assign(edit_instructions: edit_list)}
  end

  def handle_event("cancel-edit-instruction", %{"number" => number}, socket) do
    number = case Integer.parse(number) do
	       {number, ""} -> number
	       _ -> 0
	     end

    instructions =
      socket.assigns.instructions
      |> Enum.filter(& not (&1.number == number and number in socket.assigns.new_instructions))

    new_instructions =
      socket.assigns.new_instructions
      |> Enum.filter(& &1 != number)

    edit_instructions =
      socket.assigns.edit_instructions
      |> Enum.filter(& &1 != number)

    {
      :noreply,
      socket
      |> assign(edit_instructions: edit_instructions)
      |> assign(new_instructions: new_instructions)
      |> assign(instructions: instructions)
    }
  end

  def handle_event("append-instruction", _attrs, socket) do
    instructions = socket.assigns.instructions

    {new_number, new_instructions} =
      instructions
      |> Orderables.append(%{content: ""})

    {:noreply,
     socket
     |> assign(instructions: new_instructions)
     |> assign(edit_instructions: [new_number | socket.assigns.edit_instructions])
     |> assign(new_instructions: [new_number | socket.assigns.new_instructions])
    }
  end

  def handle_event("insert-instruction", %{"number" => number}, socket) do
    number = String.to_integer(number)

    {_new_number, instructions} =
      socket.assigns.instructions
      |> Orderables.insert_before(%{content: ""}, %{number: number})

    edit_instructions = [
      number |
      socket.assigns.edit_instructions
      |> Enum.map(fn
	i when i >= number -> i + 1
	i -> i
      end)
    ]
    new_instructions = [
      number |
      socket.assigns.new_instructions
      |> Enum.map(fn
	i when i >= number -> i + 1
	i -> i
      end)
    ]

    {:noreply,
     socket
     |> assign(instructions: instructions)
     |> assign(edit_instructions: edit_instructions)
     |> assign(new_instructions: new_instructions)
    }
  end

  def handle_event("delete-instruction", %{"number" => number}, socket) do
    number = String.to_integer(number)

    edit_instructions =
      socket.assigns.edit_instructions
      |> Enum.filter(& &1 != number)

    send self(), {
      :update_instructions,
      %{
	instructions: Orderables.delete(socket.assigns.instructions, %{number: number}),
	edit_instructions: edit_instructions}}

    {:noreply, socket}
  end

  def handle_event("submit-instruction-" <> number, %{"instruction-content" => content}, socket) do
    number = String.to_integer(number)
    instructions = socket.assigns.instructions

    new_instruction = %{number: number, content: content}
    instructions = Orderables.replace(instructions, new_instruction)

    edit_instructions =
      socket.assigns.edit_instructions
      |> Enum.filter(& &1 != number)

    send self(), {
      :update_instructions,
      %{
	instructions: instructions,
	edit_instructions: edit_instructions
      }
    }

    {:noreply, socket}
  end

  defp maybe_add_to_list(number, list) do
    case Integer.parse(number) do
      :error -> list
      {i, _remainder} ->
	if i not in list do
	  [i | list]
	else
	  list
	end
    end
  end

end
