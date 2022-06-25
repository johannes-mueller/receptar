defmodule ReceptarWeb.SingleTranslationLive do
  use ReceptarWeb, :live_component

  alias Receptar.Translations.Translation

  def update(assigns, socket) do
    %{language: language} = assigns

    translation =
      assigns.translatable.translations
      |> Enum.find(& &1.language == language) || %{content: ""}

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(content: translation.content)
    }
  end

  def handle_event("submit", %{"content" => content}, socket) do
    %{
      translatable: translatable,
      language: language
    } = socket.assigns

    update = %{
      update_translations: %{
	translatable: translatable,
	translations: [%{language: language, content: content}]
      }
    }

    do_send_update(socket, update)

    {:noreply, socket}
  end

  def handle_event("cancel", _attrs, socket) do
    do_send_update(socket, %{cancel_translation: socket.assigns.translatable})
    {:noreply, socket}
  end

  defp do_send_update(socket, update) do
    %{assigns:
      %{
	parent_module: parent_module,
	parent_id: parent_id,
      }
    } = socket

    send_update(
      parent_module,
      Map.merge(update, %{id: parent_id})
    )
  end

end
