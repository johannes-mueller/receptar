defmodule ReceptarWeb.TranslationLiveTest do
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Receptar.Seeder
#  import Phoenix.LiveViewTest
  import Phoenix.LiveView.Helpers

#  import Receptar.TestHelpers

  alias Receptar.Translations.Translation

  alias ReceptarWeb.TranslationLive
#  alias ReceptarWeb.TranslationTestLiveView


  describe "Socket state" do
    setup do
      insert_test_data()
      %{
	socket: %Phoenix.LiveView.Socket{},
	known_translations: [
	    %Translation{
	      language: "eo",
	      content: "salo"
	    },
	    %Translation{
	      language: "de",
	      content: "Salz"
	    }
	  ]
      }
    end

    for language <- ["sk", "en"] do
      test "default translation #{language}", %{socket: socket, known_translations: translations} do
	language = unquote(language)
	assigns = %{
	  language: language,
	  translations: translations
	}

	{:ok, socket} = TranslationLive.update(assigns, socket)

	assert %Phoenix.LiveView.Socket{
	  assigns: %{dst_translation: %{language: ^language, content: ""}}
	} = socket
      end
    end

    test "translation in default language known", %{socket: socket, known_translations: translations} do
      assigns = %{
	language: "eo",
	  translations: translations
      }

      {:ok, socket} = TranslationLive.update(assigns, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{dst_translation: %{language: "eo", content: "salo"}}
      } = socket
    end

    for language <- ["sk", "fr"] do
      test "change-dst-language event (#{language}) sets/changes dst language", fixtures do
	%{socket: socket, known_translations: translations} = fixtures

	language = unquote(language)
	assigns = %{
	  language: "eo",
	  translations: translations
	}

	{:ok, socket} = TranslationLive.update(assigns, socket)

	attrs = %{"language" => language}
	{:noreply, socket} =
	  TranslationLive.handle_event("change-dst-language", attrs, socket)

	assert %Phoenix.LiveView.Socket{
	  assigns: %{
	    language: ^language,
	    dst_translation: %{language: ^language, content: ""}
	  }
	} = socket
      end
    end

    test "change-dst-language event to known language sets content", fixtures do
      %{socket: socket, known_translations: translations} = fixtures

      assigns = %{
	language: "eo",
	translations: translations
      }

      {:ok, socket} = TranslationLive.update(assigns, socket)

      attrs = %{"language" => "de"}
      {:noreply, socket} =
	TranslationLive.handle_event("change-dst-language", attrs, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{dst_translation: %{language: "de", content: "Salz"}}
      } = socket
    end

    for {language, content} <- [{"sk", "soľ"}, {"fr", "sel"}] do
      test "change-translation-content for #{language} changes translation", fixtures do
	%{socket: socket, known_translations: translations} = fixtures

	language = unquote(language)
	content = unquote(content)
	assigns = %{
	  language: language,
	  translations: translations
	}

	{:ok, socket} = TranslationLive.update(assigns, socket)

	{:noreply, socket} =
	  TranslationLive.handle_event("change-translation-content", %{content: content}, socket)

	assert %Phoenix.LiveView.Socket{
	  assigns: %{dst_translation: %{language: ^language, content: ^content}}
	} = socket
      end
    end

    for {language, content, orig_content} <- [
	  {"eo", "saloo", "salo"}, {"de", "Salzz", "Salz"}, {"sk", "soľ", ""}
	] do
      test "save-translation-content for #{language} saves translation", fixtures do
	%{socket: socket, known_translations: translations} = fixtures

	language = unquote(language)
	content = unquote(content)
	orig_content = unquote(orig_content)
	assigns = %{
	  language: language,
	  translations: translations
	}

	{:ok, socket} = TranslationLive.update(assigns, socket)

	{:noreply, socket} =
	  TranslationLive.handle_event("change-translation-content", %{content: content}, socket)

	{:noreply, socket} =
	  TranslationLive.handle_event("save-translation-content", %{}, socket)

	%{assigns: %{translations: translations}} = socket

	translations
	|> Enum.any?(fn
	  %{language: ^language, content: ^content} -> true
	  _ -> false
	end)
	|> assert

	translations
	|> Enum.any?(fn
	  %{language: ^language, content: ^orig_content} -> true
	  _ -> false
	end)
	|> refute

      end
    end

    for {language, content} <- [{"eo", "salo"}, {"de", "Salz"}] do
      test "reset-translation-content for #{language} reset translation", fixtures do
	%{socket: socket, known_translations: translations} = fixtures

	language = unquote(language)
	content = unquote(content)
	assigns = %{
	  language: language,
	  translations: translations
	}

	{:ok, socket} = TranslationLive.update(assigns, socket)

	{:noreply, socket} =
	  TranslationLive.handle_event("change-translation-content", %{content: "uuuh"}, socket)

	{:noreply, socket} =
	  TranslationLive.handle_event("reset-translation-content", %{}, socket)

	assert %Phoenix.LiveView.Socket{
	  assigns: %{dst_translation: %{language: ^language, content: ^content}}
	} = socket
      end
    end

    test "initial state not changed", fixtures do
      %{socket: socket, known_translations: translations} = fixtures

      assigns = %{
	language: "eo",
	translations: translations
      }

      {:ok, socket} = TranslationLive.update(assigns, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{content_changed: false}
      } = socket
    end

    test "after content change state changed", fixtures do
      %{socket: socket, known_translations: translations} = fixtures

      assigns = %{
	language: "eo",
	translations: translations
      }

      {:ok, socket} = TranslationLive.update(assigns, socket)

      {:noreply, socket} =
	TranslationLive.handle_event("change-translation-content", %{content: "uuuh"}, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{content_changed: true}
      } = socket
    end

    test "after content reset state not changed", fixtures do
      %{socket: socket, known_translations: translations} = fixtures

      assigns = %{
	language: "eo",
	translations: translations
      }

      {:ok, socket} = TranslationLive.update(assigns, socket)

      {:noreply, socket} =
	TranslationLive.handle_event("change-translation-content", %{content: "uuuh"}, socket)

      {:noreply, socket} =
	TranslationLive.handle_event("reset-translation-content", %{}, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{content_changed: false}
      } = socket
    end


    for module <- [ReceptarWeb.IngredientLive, ReceptarWeb.RecipeLive] do
      test "translation done send update done to #{module}", fixtures do
	%{socket: socket, known_translations: translations} = fixtures
	module = unquote(module)
	assigns = %{
	  language: "eo",
	  translations: translations,
	  parent_module: module
	}

	{:ok, socket} = TranslationLive.update(assigns, socket)

	{:noreply, _socket} =
          TranslationLive.handle_event("done", %{}, socket)

	assert_received(
	  {
	    :phoenix, :send_update,
	    {
	      ^module,
	      "translation",
	      %{id: "translation", status: "done"}
	    }
	  }
	)
      end
    end

  end
end

defmodule ReceptarWeb.TranslationTestLiveView do
  use Phoenix.LiveView

  alias ReceptarWeb.TranslationLive

  def render(assigns) do
    ~H"<.live_component
    module={TranslationLive}
    id={@translation.number}
    translation={@translation}
    language={@language}
    />"
  end

  def mount(_params, session, socket) do
    %{
      "translation" => translation,
      "language" => language
    } = session
    socket =
      socket
      |> assign(translation: translation)
      |> assign(language: language)

    {:ok, socket}
  end
end
