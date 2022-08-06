defmodule ReceptarWeb.SearchBar do
  use ReceptarWeb, :live_view

  alias Receptar.Recipes

  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(recipes: [])
      |> assign(focused_recipe: nil)
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
      |> assign(focused_recipe: nil)

    {:noreply, socket}
  end

  def handle_event("blur", %{}, socket) do
    keep_focus = socket.assigns.focused_recipe != nil
    {
      :noreply,
      socket
      |> assign(focused: keep_focus)
    }
  end

  def handle_event("focus", %{}, socket) do
    {
      :noreply,
      socket
      |> assign(focused: true)
      |> assign(focused_recipe: nil)
    }
  end

  def handle_event("key-event", %{"key" => "ArrowDown"}, socket) do
    recipes = socket.assigns.recipes
    recipe_number = case socket.assigns.focused_recipe do
		      nil -> 0
		      x when x == length(recipes) - 1 -> x
		      x -> x + 1
		    end

    recipe = Enum.at(recipes, recipe_number)
    socket = case recipe do
	       nil -> socket
	       r -> push_event(socket, "focus-element", %{id: "suggestion-#{r.id}"})
	     end
    {
      :noreply,
      socket
      |> assign(focused_recipe: recipe_number)
    }
  end

  def handle_event("key-event", %{"key" => "ArrowUp"}, socket) do
    recipe_number = case socket.assigns.focused_recipe do
		      nil -> nil
		      0 -> nil
		      x -> x - 1
		    end

    recipe = case recipe_number do
	       nil -> nil
	       i -> Enum.at(socket.assigns.recipes, i)
	     end
    element_id = case recipe do
	       nil -> "search-bar-input"
	       r -> "suggestion-#{r.id}"
	     end
    {
      :noreply,
      socket
      |> push_event("focus-element", %{id: element_id})
      |> assign(focused_recipe: recipe_number)
    }
  end

  def handle_event("key-event", %{}, socket), do: {:noreply, socket}

  def highlight_search_string(title, search_string) do
    capitalized = Regex.run(~r/#{search_string}/i, title)
    raw String.replace(title, capitalized, "<strong>#{capitalized}</strong>")
  end
end
