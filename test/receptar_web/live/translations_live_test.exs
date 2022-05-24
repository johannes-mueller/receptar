defmodule ReceptarWeb.TranslationLiveTest do
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Receptar.Seeder
  import Phoenix.LiveViewTest
  import Phoenix.LiveView.Helpers

#  import Receptar.TestHelpers

  alias ReceptarWeb.TranslationLive
  alias ReceptarWeb.TranslationTestLiveView


  describe "Socket state" do
    setup do
      insert_test_data()
      translatable = Receptar.Substances.search("salo", "eo") |> List.first

      %{
	socket: %Phoenix.LiveView.Socket{},
	translatable: translatable
      }
    end

    for language <- ["sk", "en"] do
      test "default translation #{language}", %{socket: socket, translatable: translatable} do
	language = unquote(language)
	assigns = %{
	  language: language,
	  translatable: translatable
	}

	{:ok, socket} = TranslationLive.update(assigns, socket)

	assert %Phoenix.LiveView.Socket{
	  assigns: %{dst_translation: %{language: ^language, content: ""}}
	} = socket
      end
    end

    test "translation in default language known", %{socket: socket, translatable: translatable} do
      assigns = %{
	language: "eo",
	  translatable: translatable
      }

      {:ok, socket} = TranslationLive.update(assigns, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{dst_translation: %{language: "eo", content: "salo"}}
      } = socket
    end

    for language <- ["sk", "fr"] do
      test "change-dst-language event (#{language}) sets/changes dst language", fixtures do
	%{socket: socket, translatable: translatable} = fixtures

	language = unquote(language)
	assigns = %{
	  language: "eo",
	  translatable: translatable
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
      %{socket: socket, translatable: translatable} = fixtures

      assigns = %{
	language: "eo",
	translatable: translatable
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
	%{socket: socket, translatable: translatable} = fixtures

	language = unquote(language)
	content = unquote(content)
	assigns = %{
	  language: language,
	  translatable: translatable
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
	%{socket: socket, translatable: translatable} = fixtures

	language = unquote(language)
	content = unquote(content)
	orig_content = unquote(orig_content)
	assigns = %{
	  language: language,
	  translatable: translatable
	}

	substance_id = translatable.id

	{:ok, socket} = TranslationLive.update(assigns, socket)

	{:noreply, socket} =
	  TranslationLive.handle_event("change-translation-content", %{content: content}, socket)

	{:noreply, socket} =
	  TranslationLive.handle_event("save-translation-content", %{}, socket)

	translatable = Receptar.Substances.get_substance!(substance_id)

	translatable.translations
	|> Enum.any?(fn
	  %{language: ^language, content: ^content} -> true
	  _ -> false
	end)
	|> assert

	translatable.translations
	|> Enum.any?(fn
	  %{language: ^language, content: ^orig_content} -> true
	  _ -> false
	end)
	|> refute

	socket.assigns.translatable.translations
	|> Enum.any?(fn
	  %{language: ^language, content: ^content} -> true
	  _ -> false
	end)
	|> assert

	socket.assigns.translatable.translations
	|> Enum.any?(fn
	  %{language: ^language, content: ^orig_content} -> true
	  _ -> false
	end)
	|> refute


      end
    end

    for {language, content} <- [{"eo", "salo"}, {"de", "Salz"}] do
      test "reset-translation-content for #{language} reset translation", fixtures do
	%{socket: socket, translatable: translatable} = fixtures

	language = unquote(language)
	content = unquote(content)
	assigns = %{
	  language: language,
	  translatable: translatable
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
      %{socket: socket, translatable: translatable} = fixtures

      assigns = %{
	language: "eo",
	translatable: translatable
      }

      {:ok, socket} = TranslationLive.update(assigns, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{content_changed: false}
      } = socket
    end

    test "after content change state changed", fixtures do
      %{socket: socket, translatable: translatable} = fixtures

      assigns = %{
	language: "eo",
	translatable: translatable
      }

      {:ok, socket} = TranslationLive.update(assigns, socket)

      {:noreply, socket} =
	TranslationLive.handle_event("change-translation-content", %{content: "uuuh"}, socket)

      assert %Phoenix.LiveView.Socket{
	assigns: %{content_changed: true}
      } = socket
    end

    test "after content reset state not changed", fixtures do
      %{socket: socket, translatable: translatable} = fixtures

      assigns = %{
	language: "eo",
	translatable: translatable
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
	%{socket: socket, translatable: translatable} = fixtures
	module = unquote(module)
	assigns = %{
	  language: "eo",
	  translatable: translatable,
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

  describe "Connection stat" do
    setup %{conn: conn} do
      insert_test_data()
      register_and_log_in_user(%{conn: conn})

      translatable = Receptar.Substances.search("salo", "eo") |> List.first
      {:ok, %{session: %{"translatable" => translatable, "language" => "eo"}}}
    end

    test "TranslationLive view has a form", %{conn: conn, session: session} do

      {:ok, view, _html} = live_isolated(conn, TranslationTestLiveView, session: session)

      form_element = element(view, "form")

      assert render(form_element) =~ ~r/phx-submit="submit"/
      assert render(form_element) =~ ~r/phx-change="change-translation-content"/
    end

  end
end

defmodule ReceptarWeb.TranslationTestLiveView do
  use Phoenix.LiveView

  alias ReceptarWeb.TranslationLive

  def render(assigns) do
    ~H"<.live_component
    module={TranslationLive}
    id={@translatable.id}
    translatable={@translatable}
    language={@language}
    />"
  end

  def mount(_params, session, socket) do
    %{
      "translatable" => translatable,
      "language" => language
    } = session
    socket =
      socket
      |> assign(translatable: translatable)
      |> assign(language: language)

    {:ok, socket}
  end
end
