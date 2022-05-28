defmodule ReceptarWeb.TranslationsLiveTest do
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Receptar.Seeder
  import Phoenix.LiveViewTest
  import Phoenix.LiveView.Helpers

#  import Receptar.TestHelpers
  alias Receptar.Translations.Translation
  alias ReceptarWeb.TranslationsLive
  alias ReceptarWeb.TranslationsTestLiveView


  describe "Socket state" do
    setup do
      insert_test_data()
      translatable = Receptar.Substances.search("salo", "eo") |> List.first

      %{
	socket: %Phoenix.LiveView.Socket{},
	translatable: translatable
      }
    end

    test "default empty active_languages", %{socket: socket, translatable: translatable} do
      assigns = %{translatable: translatable}
      {:ok, socket} = TranslationsLive.update(assigns, socket)

      assert socket.assigns.active_languages == []
    end

    test "translations sorted by language", %{socket: socket, translatable: translatable} do
      assigns = %{translatable: translatable}
      {:ok, socket} = TranslationsLive.update(assigns, socket)

      assert [%{language: "de"}, %{language: "eo"}] = socket.assigns.translatable.translations
    end


    test "activate-language event activates language", %{socket: socket, translatable: translatable} do
      assigns = %{translatable: translatable}
      {:ok, socket} = TranslationsLive.update(assigns, socket)

      {:noreply, socket} =
	TranslationsLive.handle_event("activate-language", %{"language" => "eo"}, socket)

      assert socket.assigns.active_languages == ["eo"]

      {:noreply, socket} =
	TranslationsLive.handle_event("activate-language", %{"language" => "de"}, socket)

      assert socket.assigns.active_languages == ["de", "eo"]
    end

    for language <- ["eo", "de"] do
      test "submit translation content deactivates #{language}", %{socket: socket, translatable: translatable} do
	language = unquote(language)
	assigns = %{translatable: translatable}
	{:ok, socket} = TranslationsLive.update(assigns, socket)

	{:noreply, socket} =
	  TranslationsLive.handle_event("activate-language", %{"language" => language}, socket)

	attrs = %{"language" => language, "content" => "uuh"}
	{:noreply, socket} =
	  TranslationsLive.handle_event("submit-changed-translation", attrs, socket)

	assert socket.assigns.active_languages == []
      end
    end

    for {language, content, orig_content} <- [
	  {"eo", "saloo", "salo"}, {"de", "Salzz", "Salz"}
	] do
      test "submit translation content for #{language} saves translation", fixtures do
	%{socket: socket, translatable: translatable} = fixtures

	language = unquote(language)
	content = unquote(content)
	orig_content = unquote(orig_content)
	assigns = %{translatable: translatable}

	translation = Enum.filter(translatable.translations, &(&1.language == language))
	[ %{id: translation_id} | _] = translation

	{:ok, socket} = TranslationsLive.update(assigns, socket)

	{:noreply, socket} =
	  TranslationsLive.handle_event("activate-language", %{"language" => language}, socket)

	attrs = %{"language" => language, "content" => content}
	{:noreply, socket} =
	  TranslationsLive.handle_event("submit-changed-translation", attrs, socket)

	assert socket.assigns.translatable.translations
	|> Enum.any?(fn
	  %Translation{id: ^translation_id, language: ^language, content: ^content} -> true
	  _ -> false
	end)

	refute socket.assigns.translatable.translations
	|> Enum.any?(fn
	  %{language: ^language, content: ^orig_content} -> true
	  _ -> false
	end)

      end
    end

    test "submit changed translation order persists", %{socket: socket, translatable: translatable} do
      assigns = %{translatable: translatable}
      {:ok, socket} = TranslationsLive.update(assigns, socket)

      {:noreply, socket} =
	TranslationsLive.handle_event("submit-changed-translation", %{"language" => "eo", "content" => "saalo"}, socket)

      assert [%{language: "de"}, %{language: "eo"}] = socket.assigns.translatable.translations
    end

    for {language, content} <- [{"sk", "soľ"}, {"fr", "sel"}] do
      test "submit-new-translation #{language} adds translation", %{socket: socket, translatable: translatable} do
	language = unquote(language)
	content = unquote(content)
	assigns = %{translatable: translatable}
	{:ok, socket} = TranslationsLive.update(assigns, socket)

	{:noreply, socket} =
	  TranslationsLive.handle_event("submit-new-translation", %{"language" => language, "content" => content}, socket)

	socket.assigns.translatable.translations
	|> Enum.any?(fn
	  %{language: ^language, content: ^content} -> true
	  _ -> false
	end)
	|> assert
      end
    end

    for {language, content} <- [{"sk", "soľ"}, {"fr", "sel"}] do
      test "submit-new-translation #{language} saves translation", %{socket: socket, translatable: translatable} do
	language = unquote(language)
	content = unquote(content)
	assigns = %{translatable: translatable}
	{:ok, socket} = TranslationsLive.update(assigns, socket)

	{:noreply, socket} =
	  TranslationsLive.handle_event("submit-new-translation", %{"language" => language, "content" => content}, socket)

	socket.assigns.translatable.translations
	|> Enum.any?(fn
	  %{language: ^language, content: ^content} -> true
	  _ -> false
	end)
	|> assert

      end
    end

    test "submit new translation order persists", %{socket: socket, translatable: translatable} do
      assigns = %{translatable: translatable}
      {:ok, socket} = TranslationsLive.update(assigns, socket)

      {:noreply, socket} =
	TranslationsLive.handle_event("submit-new-translation", %{"language" => "sk", "content" => "soľ"}, socket)

      assert [%{language: "de"}, %{language: "eo"}, %{language: "sk"}] = socket.assigns.translatable.translations
    end

    for language <- ["eo", "de"] do
      test "cancel translation content deactivates #{language}", %{socket: socket, translatable: translatable} do
	language = unquote(language)
	assigns = %{translatable: translatable}
	{:ok, socket} = TranslationsLive.update(assigns, socket)

	{:noreply, socket} =
	  TranslationsLive.handle_event("activate-language", %{"language" => language}, socket)

	attrs = %{"language" => language}
	{:noreply, socket} =
	  TranslationsLive.handle_event("cancel-translation", attrs, socket)

	assert socket.assigns.active_languages == []
      end
    end

    for {module, module_id} <- [{ReceptarWeb.IngredientsLive, "ingredients"}, {ReceptarWeb.RecipeLive, "recipe"}] do
      test "translations done send update done to #{module}", fixtures do
        %{socket: socket, translatable: translatable} = fixtures
        module = unquote(module)
	module_id = unquote(module_id)
        assigns = %{
          language: "eo",
          translatable: translatable,
          parent_module: module,
	  parent_id: module_id
        }

        {:ok, socket} = TranslationsLive.update(assigns, socket)

        {:noreply, _socket} =
          TranslationsLive.handle_event("done", %{}, socket)

	expected_translations = Enum.sort(translatable.translations, & &1.language <= &2.language)

        assert_received(
          {
            :phoenix, :send_update,
            {
              ^module,
              ^module_id,
              %{id: ^module_id, update_translations: %{translations: ^expected_translations}}
            }
          }
        )
      end
    end
  end

  describe "Connection state" do
    setup %{conn: conn} do
      insert_test_data()
      register_and_log_in_user(%{conn: conn})

      translatable = Receptar.Substances.search("salo", "eo") |> List.first
      {:ok, %{session: %{
		 "translatable" => translatable,
		 "parent_module" => Receptar.RecipeLive,
		 "parent_id" => "recipe"
	      }}}
    end

    test "view does not have a change-translation form by default", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, TranslationsTestLiveView, session: session)

      refute view |> has_element?("form.change-translation")
    end

    test "has spans for translation content", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, TranslationsTestLiveView, session: session)

      translatable_id = session["translatable"].id
      assert view |> has_element?("span#translation-content-eo-#{translatable_id}", "salo")
      assert view |> has_element?("span#translation-content-de-#{translatable_id}", "Salz")
      refute view |> has_element?("span#translation-content-sk-#{translatable_id}")
      refute view |> has_element?("span#translation-content-fr-#{translatable_id}")
    end

    test "has spans for translation content alternate", %{conn: conn, session: session} do
      session = %{ session |
		   "translatable" => %{
		     id: 12345,
		     translations: [
		       %{language: "sk", content: "soľ"},
		       %{language: "fr", content: "sel"}
		     ]
		   }
		 }
      {:ok, view, _html} = live_isolated(conn, TranslationsTestLiveView, session: session)

      translatable_id = session["translatable"].id
      refute view |> has_element?("span#translation-content-eo-#{translatable_id}")
      refute view |> has_element?("span#translation-content-de-#{translatable_id}")
      assert view |> has_element?("span#translation-content-sk-#{translatable_id}", "soľ")
      assert view |> has_element?("span#translation-content-fr-#{translatable_id}", "sel")
    end

    for language <- ["eo", "de"] do
      test "has form for language #{language} after clicking eo span", %{conn: conn, session: session} do
	language = unquote(language)
	{:ok, view, _html} = live_isolated(conn, TranslationsTestLiveView, session: session)
	translatable_id = session["translatable"].id

	view
	|> element("span#translation-content-#{language}-#{translatable_id}")
	|> render_click()

	html = view |> element("form#change-translation-form-#{language}-#{translatable_id}") |> render()

	assert html =~ ~r/phx-submit="submit-changed-translation"/
      end
    end

    for language <- ["eo", "de"] do
      test "view does not have a change-translation form after cancel #{language}", %{conn: conn, session: session} do
	language = unquote(language)
	{:ok, view, _html} = live_isolated(conn, TranslationsTestLiveView, session: session)
	translatable_id = session["translatable"].id

	view
	|> element("span#translation-content-#{language}-#{translatable_id}")
	|> render_click()

	view
	|> element("button#cancel-translation-#{language}-#{translatable_id}")
	|> render_click()

	refute view |> has_element?("form.change-translation")
      end
    end

    for language <- ["eo", "de"] do
      test "view does not have a change-translation form after submit #{language}", %{conn: conn, session: session} do
	language = unquote(language)
	{:ok, view, _html} = live_isolated(conn, TranslationsTestLiveView, session: session)
	translatable_id = session["translatable"].id

	view
	|> element("span#translation-content-#{language}-#{translatable_id}")
	|> render_click()

	view
	|> element("form#change-translation-form-#{language}-#{translatable_id}")
	|> render_submit()

	refute view |> has_element?("form.change-translation")
      end
    end

    test "view adds translation when add-translation form submits", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, TranslationsTestLiveView, session: session)
      translatable_id = session["translatable"].id

      view
      |> element("form#add-translation-form-#{translatable_id}")
      |> render_submit()
    end

    test "view adds translation when add-translation form submits and saves", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, TranslationsTestLiveView, session: session)
      translatable_id = session["translatable"].id

      view
      |> element("form#add-translation-form-#{translatable_id}")
      |> render_submit(%{"language" => "sk", "content" => "soľ"})

      assert view |> has_element?("span#translation-content-sk-#{translatable_id}", "soľ")
    end

    test "translation done sends done signal", %{conn: conn, session: session} do
      {:ok, view, _html} = live_isolated(conn, TranslationsTestLiveView, session: session)

      view |> element("button.translation-done") |> render_click()

      IO.warn("assertion missing")
    end
  end
end

defmodule ReceptarWeb.TranslationsTestLiveView do
  use Phoenix.LiveView

  alias ReceptarWeb.TranslationsLive

  def render(assigns) do
    ~H"<.live_component
    module={TranslationsLive}
    id={@translatable.id}
    translatable={@translatable}
    parent_module={@parent_module}
    parent_id={@parent_id}
    />"
  end

  def mount(_params, session, socket) do
    %{
      "translatable" => translatable,
      "parent_module" => parent_module,
      "parent_id" => parent_id
    } = session
    socket =
      socket
      |> assign(translatable: translatable)
      |> assign(parent_module: parent_module)
      |> assign(parent_id: parent_id)

    {:ok, socket}
  end
end
