defmodule ReceptarWeb.SingleTranslationLive do
  use ReceptarWeb, :live_component

  def update(assigns, socket) do
    %{language: language} = assigns

    translation =
      assigns.translatable.translations
      |> Enum.find(& &1.language == language) || %{content: ""}

    {
      :ok,
      socket
      |> assign(Map.put_new(assigns, :textarea, false))
      |> assign(content: translation.content)
    }
  end

  def handle_event("submit", %{"content" => content}, socket) do
    %{
      translatable: translatable,
      language: language
    } = socket.assigns

    update = {
      :update_translations, %{
	translatable: translatable,
	translations: [%{language: language, content: content}]

      }
    }

    do_send_update(socket, update)

    {:noreply, socket}
  end

  def handle_event("cancel", _attrs, socket) do
    do_send_update(socket, {:cancel_translation, socket.assigns.translatable})
    {:noreply, socket}
  end

  defp do_send_update(%{assigns: %{parent_module: pm, parent_id: pid}}, {key, value}) do
    send_update(pm, Map.put(%{id: pid}, key, value))
  end

  defp do_send_update(_socket, update) do
    send self(), update
  end

end
