defmodule ReceptarWeb.SearchBar do
  use ReceptarWeb, :live_view

  alias Receptar.Recipes

  def mount(params, session, socket) do
    socket =
      socket
      |> assign(recipes: [])
      |> assign(unambigous: "")
      |> assign(language: session["language"])

    {:ok, socket, layout: false}
  end

  def handle_event("search-event", %{"search-string" => ""}, socket) do
    {:noreply, socket |> assign(recipes: [])}
  end

  def handle_event("search-event", %{"search-string" => search_string}, socket) do
    language = socket.assigns.language
    recipes = Recipes.search(%{"title" => search_string}, language)
    |> Recipes.translate(language)

    unambigous =
      recipes
      |> Enum.map(& &1.title)
      |> Enum.filter(& String.starts_with?(String.downcase(&1), search_string))
      |> find_unambigous

    socket =
      socket
      |> assign(recipes: recipes)
      |> assign(unambigous: unambigous)

    {:noreply, socket}
  end

  defp find_unambigous([_] = titles) when length(titles) == 1 do
    Enum.at(titles, 0)
  end

  defp find_unambigous(titles, subindex \\ 1) do
    unique =
      titles
      |> Enum.map(& String.slice(&1, 0, subindex))
      |> Enum.uniq

    if length(unique) > 1 do
      String.slice(Enum.at(titles, 0), 0, subindex-1)
    else
      find_unambigous(titles, subindex+1)
    end
  end
end
