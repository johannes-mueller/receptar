defmodule ReceptarWeb.RecipeLive do
  use ReceptarWeb, :live_view

  alias Receptar.Recipes
  alias Receptar.Translations

  alias ReceptarWeb.Helpers

  import ReceptarWeb.RecipeController

  alias ReceptarWeb.InstructionsLive
  alias ReceptarWeb.IngredientsLive

  def mount(params, _session, socket) do
    language = Helpers.determine_language(params)

    socket = socket
    |> assign(language: language)
    |> assign(recipe: query_recipe(params))
    |> prepare_form()
    |> assign(edit_ingredients: [])
    |> assign(edit_instructions: [])

    {:ok, socket}
  end

  defp prepare_form(socket) do
    socket
    |> assign(edit_title: socket.assigns.recipe.translations == [])
    |> assign(submit_title_disabled: true)
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

  def handle_event("title-change", %{"title" => title}, socket) do
    {:noreply, socket |> assign(submit_title_disabled: title == "")}
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

  def handle_info({:update_translations, update}, socket) do
    %{translatable: translatable, translations: translations} = update
    Translations.update_translations(translatable, translations)

    recipe_id = socket.assigns.recipe.id
    updated_recipe = Recipes.get_recipe!(recipe_id)

    {:noreply,
     socket
     |> assign(recipe: updated_recipe |> Recipes.translate(socket.assigns.language))
    }
  end
end
