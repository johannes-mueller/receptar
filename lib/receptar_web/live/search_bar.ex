defmodule ReceptarWeb.SearchBar do
  use ReceptarWeb, :live_view

  alias Receptar.Recipes

  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(recipes: [])
      |> assign(language: session["language"])
      |> assign(search_string: "")
      |> assign(focused: true)

    {:ok, socket, layout: false}
  end

  def handle_event("search-event", %{"title" => ""}, socket) do
    {
      :noreply,
      socket
      |> assign(recipes: [])
      |> assign(search_string: "")
    }
  end

  def handle_event("search-event", %{"title" => search_string}, socket) do
    language = socket.assigns.language
    recipes = Recipes.search(%{"title" => search_string}, language)
    |> Recipes.translate(language)

    socket =
      socket
      |> assign(recipes: recipes)
      |> assign(search_string: search_string)

    {:noreply, socket}
  end

  def handle_event("blur", %{}, socket) do
    {:noreply, socket |> assign(focused: false)}
  end

  def handle_event("focus", %{}, socket) do
    {:noreply, socket |> assign(focused: true)}
  end

  def highlight_search_string(title, search_string) do
    capitalized = Regex.run(~r/#{search_string}/i, title)
    raw String.replace(title, capitalized, "<strong>#{capitalized}</strong>")
  end
end
