alias Receptar.Translations

defmodule ReceptarWeb.TranslationLive do
  use ReceptarWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_initial_translation
    }
  end

  def handle_event("change-event", %{"_target" => ["dst-language"], "dst-language" => language}, socket) do
    {:noreply,
     socket
     |> assign(language: language)
     |> assign_initial_translation
    }
  end

  def handle_event("change-event", %{"_target" => ["translation-content"], "translation-content" => content}, socket) do
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
    %{assigns: %{translatable: translatable, dst_translation: dst_translation}} = socket
    %{language: dst_language} = dst_translation

    translation = Enum.find(translatable.translations, fn tr -> tr.language == dst_language end)

    if translation do
      Receptar.Translations.update_translation(translation, Map.from_struct(dst_translation))
    else
      Receptar.Translations.add_translation(translatable, dst_translation)
    end

    {:noreply,
     socket
     |> update_translations
    }
  end

  def handle_event("done", _attrs, socket) do
    %{assigns: %{parent_module: parent_module}} = socket

    send_update(parent_module, id: "translation", status: "done")
    {:noreply, socket}
  end

  defp assign_initial_translation(socket) do
    %{assigns: %{translatable: translatable, language: language}} = socket

    initial =
      translatable.translations
      |> Enum.find(%{language: language, content: ""}, &(&1.language == language))

    socket
    |> assign(dst_translation: initial)
    |> assign(content_changed: false)
  end

  defp update_translations(socket) do
    %{assigns: %{translatable: translatable, dst_translation: dst_translation}} = socket
    %{language: dst_language} = dst_translation

    translations =
      translatable.translations
      |> Enum.reject(fn
        %{language: ^dst_language} -> true
        _ -> false
      end)

     socket
     |> assign(translatable: %{translatable | translations: [dst_translation | translations]})
  end
end
