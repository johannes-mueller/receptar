defmodule ReceptarWeb.TranslationsLive do
  use ReceptarWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(active_languages: [])
    }
  end

  def handle_event("activate-language", %{"language" => language}, socket) do
    {:noreply,
     socket
     |> assign(active_languages: [language | socket.assigns.active_languages])
     }
  end

  def handle_event("submit-changed-translation", %{"language" => language, "content" => content}, socket) do
    {:noreply,
     socket
     |> deactivate_language(language)
     |> update_translations(language, content)
    }
  end

  def handle_event("submit-new-translation", %{"language" => language, "content" => content}, socket) do
    translatable = socket.assigns.translatable
    translations = [%{language: language, content: content} | translatable.translations]

    {:noreply,
     socket
     |> assign(translatable: %{translatable | translations: translations})
    }
  end

  def handle_event("cancel-translation", %{"language" => language}, socket) do
    {:noreply, deactivate_language(socket, language)}
  end

  def handle_event("done", _attrs, socket) do
    %{assigns:
      %{
	parent_module: parent_module,
	parent_id: parent_id,
	translatable: translatable
      }
    } = socket

    send_update(parent_module, id: parent_id, update_translations: translatable)

    {:noreply, socket}
  end

  defp deactivate_language(socket, language) do
    active_languages =
      socket.assigns.active_languages
      |> Enum.reject(&(&1 == language))

    socket |> assign(active_languages: active_languages)
  end

  defp update_translations(socket, language, content) do
    translations =
      socket.assigns.translatable.translations
      |> Enum.reject(& &1.language == language)

    existing_translation =
      socket.assigns.translatable.translations
      |> Enum.find(& &1.language == language)

    socket
    |> assign(translatable: %{
	  socket.assigns.translatable | translations: [
	    %{existing_translation | content: content} | translations
	  ]
    })
  end
end
