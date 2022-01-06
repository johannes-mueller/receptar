defmodule ReceptarWeb.RecipeLive do
  use ReceptarWeb, :live_view

  alias Receptar.Recipes
  alias ReceptarWeb.Helpers

  alias ReceptarWeb.RecipeView
  import ReceptarWeb.RecipeController

  def render(assigns) do
    RecipeView.render("edit.html", assigns)
  end

  def mount(params, _session, socket) do
    language = Helpers.determine_language(params)
    recipe = query_recipe(params)

    socket = socket
    |> assign(language: language)
    |> assign(recipe: recipe)
    |> assign(edit_title: false)
    |> assign(edit_ingredients: [])
    |> assign(edit_instructions: [])

    {:ok, socket}
  end

  def handle_event("edit-title", _attrs, socket) do
    {:noreply, socket |> assign(edit_title: true)}
  end

  def handle_event("submit-title", %{"title" => title}, socket) do
    recipe = socket.assigns.recipe
    language = Helpers.determine_language(socket.assigns)

    {:ok, recipe} = Recipes.update_recipe(recipe, %{title: title, language: language})

    {:noreply,
     socket
     |> assign(recipe: recipe |> Recipes.translate(language))
     |> assign(edit_title: false)
    }
  end

  def handle_event("cancel-edit-title", _attrs, socket) do
    {:noreply, socket |> assign(edit_title: false)}
  end

  def handle_info({:update_ingredients, %{ingredients: ingredients}}, socket) do
    language = socket.assigns.language

    change_attrs = %{ingredients: ingredients, language: language}

    {:ok, recipe} = Recipes.update_recipe(socket.assigns.recipe, change_attrs)

    recipe =
      Recipes.get_recipe!(recipe.id)
      |> Recipes.translate("eo")

    {:noreply, socket |> assign(recipe: recipe)}
  end

  def handle_info({:update_instructions, attrs}, socket) do
    %{instructions: instructions} = attrs
    language = socket.assigns.language

    change_attrs = %{instructions: instructions, language: language}
    {:ok, recipe} = Recipes.update_recipe(socket.assigns.recipe, change_attrs)

    {:noreply, socket |> assign(recipe: recipe |> Recipes.translate(language))}
  end
end
