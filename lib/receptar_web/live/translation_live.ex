defmodule ReceptarWeb.TranslationLive do
  use ReceptarWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_initial_translation
    }
  end

  def handle_event("change-dst-language", %{"language" => language}, socket) do
    {:noreply,
     socket
     |> assign(language: language)
     |> assign_initial_translation
    }
  end

  def handle_event("change-translation-content", %{content: content}, socket) do
    %{assigns: %{dst_translation: translation}} = socket

    {:noreply,
     socket
     |> assign(%{dst_translation: %{translation | content: content}})
     |> assign(%{content_changed: true})
    }
  end

  def handle_event("reset-translation-content", _attrs, socket) do
    {:noreply,
     socket
     |> assign_initial_translation
    }
  end

  def handle_event("save-translation-content", _attrs, socket) do
    %{assigns: %{translations: translations, dst_translation: dst_translation}} = socket
    %{language: dst_language} = dst_translation

    translations =
      translations
      |> Enum.reject(fn
        %{language: ^dst_language} -> true
        _ -> false
      end)

    {:noreply,
     socket
     |> assign(translations: [dst_translation | translations])
    }
  end

  def handle_event("done", _attrs, socket) do
    %{assigns: %{parent_module: parent_module}} = socket

    send_update(parent_module, id: "translation", status: "done")
    {:noreply, socket}
  end

  defp assign_initial_translation(socket) do
    %{assigns: %{translations: translations, language: language}} = socket

    initial =
      translations
      |> Enum.find(%{language: language, content: ""}, &(&1.language == language))

    socket
    |> assign(dst_translation: initial)
    |> assign(content_changed: false)
  end
end
