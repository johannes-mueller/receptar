defmodule ReceptarWeb.SingleTranslationLiveTest do
  use ReceptarWeb.ConnCase
  use ExUnit.Case
  import Receptar.Seeder
  import Phoenix.LiveViewTest
  import Phoenix.LiveView.Helpers

  alias ReceptarWeb.SingleTranslationLive
  alias ReceptarWeb.SingleTranslationLiveView


  describe "Socket state" do
    setup do
      insert_test_data()
      translatable = Receptar.Substances.search("salo", "eo") |> List.first

      %{
	socket: %Phoenix.LiveView.Socket{},
	translatable: translatable
      }
    end

    for language <- ["en", "sk"] do
      test "with unknown language #{language} has empty translation text", fixtures do
	language = unquote(language)
	%{socket: socket, translatable: translatable} = fixtures
	assigns = %{translatable: translatable, language: language}
	{:ok, socket} = SingleTranslationLive.update(assigns, socket)

	assert %{content: ""} = socket.assigns
      end
    end

    for {language, content} <- [{"eo", "salo"}, {"de", "Salz"}] do
      test "with known language #{language} has empty translation text", fixtures do
	language = unquote(language)
	content = unquote(content)
	%{socket: socket, translatable: translatable} = fixtures
	assigns = %{translatable: translatable, language: language}
	{:ok, socket} = SingleTranslationLive.update(assigns, socket)

	assert %{content: ^content} = socket.assigns
      end
    end

    for {module, module_id, language, content} <- [
	  {ReceptarWeb.IngredientsLive, "ingredients", "sk", "soľ"},
	  {ReceptarWeb.RecipeLive, "recipe", "fr", "sel"}
	] do
	test "submit event sends update to #{module}", fixtures do
          module = unquote(module)
	  module_id = unquote(module_id)
	  language = unquote(language)
	  content = unquote(content)
	  %{socket: socket, translatable: translatable} = fixtures
	  assigns = %{
	    translatable: translatable,
	    language: language,
	    parent_module: module,
	    parent_id: module_id
	  }
	  {:ok, socket} = SingleTranslationLive.update(assigns, socket)

	  {:noreply, _socket} =
	    SingleTranslationLive.handle_event("submit", %{"content" => content}, socket)

	  expected_translations = [%{language: language, content: content}]

	  assert_received(
            {
              :phoenix, :send_update,
              {
		^module,
		^module_id,
		%{id: ^module_id, update_translations: %{
		     translations: ^expected_translations,
		     translatable: ^translatable
		  }
		}
              }
            }
	  )
	end

	test "cancel event sends update to component #{module}", fixtures do
          module = unquote(module)
	  module_id = unquote(module_id)
	  language = unquote(language)
	  %{socket: socket, translatable: translatable} = fixtures
	  assigns = %{
	    translatable: translatable,
	    language: language,
	    parent_module: module,
	    parent_id: module_id
	  }
	  {:ok, socket} = SingleTranslationLive.update(assigns, socket)

	  {:noreply, _socket} =
	    SingleTranslationLive.handle_event("cancel", %{}, socket)

	  assert_received(
            {
	      :phoenix, :send_update,
	      {
		^module,
		^module_id,
		%{id: ^module_id, cancel_translation: ^translatable}
	      }
	    }
	  )
	end
    end

    test "cancel event sends update to view", fixtures do
      %{socket: socket, translatable: translatable} = fixtures
      assigns = %{
	translatable: translatable,
	language: "eo"
      }
      {:ok, socket} = SingleTranslationLive.update(assigns, socket)

      {:noreply, _socket} =
	SingleTranslationLive.handle_event("cancel", %{}, socket)

      assert_received({:cancel_translation, ^translatable})

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
		 "parent_id" => "recipe",
	      }}}
    end

    test "unknown target language has empty input field", %{conn: conn, session: session} do
      session = Map.merge(session, %{"language" => "sk"})
      {:ok, view, _html} = live_isolated(conn, SingleTranslationLiveView, session: session)
      translatable_id = session["translatable"].id

      assert view
      |> element("form#edit-translation-#{translatable_id} input.edit-translation-input")
      |> render() =~ ~r/value=""/
    end

    test "submit click does not fail", %{conn: conn, session: session} do
      session = Map.merge(session, %{"language" => "sk"})
      {:ok, view, _html} = live_isolated(conn, SingleTranslationLiveView, session: session)
      translatable_id = session["translatable"].id

      assert view
      |> element("form#edit-translation-#{translatable_id}")
      |> render_submit()  # no assertion necessary (enforces phx-target={@myself} and form correctness)
    end

    test "cancel click does not fail", %{conn: conn, session: session} do
      session = Map.merge(session, %{"language" => "sk"})
      {:ok, view, _html} = live_isolated(conn, SingleTranslationLiveView, session: session)
      translatable_id = session["translatable"].id

      assert view
      |> element("form#edit-translation-#{translatable_id} button.cancel")
      |> render_click()  # no assertion necessary (enforces phx-target={@myself})
    end

    test "known target language has empty input field", %{conn: conn, session: session} do
      session = Map.merge(session, %{"language" => "eo"})
      {:ok, view, _html} = live_isolated(conn, SingleTranslationLiveView, session: session)
      translatable_id = session["translatable"].id

      assert view
      |> element("form#edit-translation-#{translatable_id} input.edit-translation-input")
      |> render() =~ ~r/value="salo"/
    end

    for language <- ["en", "sk"] do
      test "target language #{language} is rendered in label as flag", %{conn: conn, session: session} do
	language = unquote(language)
	session = Map.merge(session, %{"language" => language})
	{:ok, view, _html} = live_isolated(conn, SingleTranslationLiveView, session: session)
	translatable_id = session["translatable"].id

	assert view
	|> has_element?("form#edit-translation-#{translatable_id} label.edit-translation-label-#{language}")
      end
    end

    test "known languages shown in translation widget", %{conn: conn, session: session} do
      session = Map.merge(session, %{"language" => "sk"})
      {:ok, view, _html} = live_isolated(conn, SingleTranslationLiveView, session: session)

      assert view
      |> element("ul.translations li.translation-eo")
      |> render() =~ ~r/salo/

      assert view
      |> element("ul.translations li.translation-de")
      |> render() =~ ~r/Salz/
    end

    test "known languages shown in translation widget alternative", %{conn: conn, session: session} do
      session = Map.merge(session, %{"language" => "de"})
      translatable = %{
	session["translatable"] | translations: [
	  %{language: "sk", content: "soľ"},
	  %{language: "fr", content: "sel"}
	]
      }
      session = %{session | "translatable" => translatable}
      {:ok, view, _html} = live_isolated(conn, SingleTranslationLiveView, session: session)

      assert view
      |> element("ul.translations li.translation-fr")
      |> render() =~ ~r/sel/
      |> assert

      assert view
      |> element("ul.translations li.translation-sk")
      |> render() =~ ~r/soľ/
      |> assert
    end
  end
end

defmodule ReceptarWeb.SingleTranslationLiveView do
  use Phoenix.LiveView

  alias ReceptarWeb.SingleTranslationLive

  def render(assigns) do
    ~H"<.live_component
    module={SingleTranslationLive}
    id={@translatable.id}
    translatable={@translatable}
    parent_module={@parent_module}
    parent_id={@parent_id}
    language={@language}
    />"
  end

  def mount(_params, session, socket) do
    %{
      "translatable" => translatable,
      "parent_module" => parent_module,
      "parent_id" => parent_id,
      "language" => language
    } = session
    socket =
      socket
      |> assign(translatable: translatable)
      |> assign(language: language)
      |> assign(parent_module: parent_module)
      |> assign(parent_id: parent_id)

    {:ok, socket}
  end
end
