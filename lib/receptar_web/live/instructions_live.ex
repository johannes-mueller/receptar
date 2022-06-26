defmodule ReceptarWeb.InstructionsLive do
  use ReceptarWeb, :live_component

  alias Receptar.Orderables
  alias ReceptarWeb.Helpers
  alias ReceptarWeb.SingleTranslationLive


  def update(%{update_translations: %{translatable: %{translations: []}} = update}, socket) do
    %{translatable: %{number: number}, translations: translations} = update

    instructions = socket.assigns.instructions

    content =
      translations
      |> Enum.find(& &1.language == socket.assigns.language)
      |> then(& &1.content)

    new_instruction = %{content: content, number: number, translations: translations}
    instructions = Orderables.replace(instructions, new_instruction)

    send self(), {:update_instructions, %{instructions: instructions}}

    {:ok, socket}
  end

  def update(%{update_translations: update}, socket) do
    send self(), {:update_translations, update}

    %{translatable: %{number: number}} = update

    edit_instructions =
      socket.assigns.edit_instructions
      |> Enum.filter(& &1 != number)

    {:ok, socket |> assign(edit_instructions: edit_instructions)}
  end

  def update(%{cancel_translation: %{number: number}}, socket) do
    instructions =
      socket.assigns.instructions
      |> Enum.filter(& &1.number != number or &1.content != "")

    {
      :ok,
      socket
      |> assign(instructions: instructions)
      |> assign(edit_instructions: [])
    }
  end

  def update(params, socket) do
    socket = socket
    |> assign(instructions: params.instructions)
    |> assign(edit_instructions: params.edit_instructions)
    |> assign(language: params.language)
    |> assign(new_instructions: [])

    {:ok, socket}
  end

  def handle_event("edit-instruction", %{"number" => number}, socket) do
    edit_list = maybe_add_to_list(number, socket.assigns.edit_instructions)
    {:noreply, socket |> assign(edit_instructions: edit_list)}
  end

  def handle_event("append-instruction", _attrs, socket) do
    instructions = socket.assigns.instructions

    {new_number, new_instructions} =
      instructions
      |> Orderables.append(%{content: "", translations: []})

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
      |> Orderables.insert_before(%{content: "", translations: []}, %{number: number})

    edit_instructions = Helpers.insert_number_at(socket.assigns.edit_instructions, number)
    new_instructions = Helpers.insert_number_at(socket.assigns.new_instructions, number)

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
	edit_instructions: edit_instructions
      }
    }

    {:noreply, socket}
  end

  def handle_event("push-instruction", %{"number" => number}, socket) do
    number = String.to_integer(number)
    instructions =
      socket.assigns.instructions
      |> Orderables.push(number)

    send self(), {
      :update_instructions,
      %{
	instructions: instructions
      }
    }

    {:noreply, socket}
  end

  def handle_event("pull-instruction", %{"number" => number}, socket) do
    number = String.to_integer(number)
    instructions =
      socket.assigns.instructions
      |> Orderables.pull(number)

    send self(), {
      :update_instructions,
      %{
	instructions: instructions
      }
    }

    {:noreply, socket}
  end
end
