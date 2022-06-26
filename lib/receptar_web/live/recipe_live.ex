defmodule ReceptarWeb.RecipeLive do
  use ReceptarWeb, :live_view

  alias Receptar.Recipes
  alias Receptar.Recipes.Recipe
  alias Receptar.Translations

  import ReceptarWeb.RecipeController

  alias ReceptarWeb.InstructionsLive
  alias ReceptarWeb.IngredientsLive
  alias ReceptarWeb.SingleTranslationLive

  def mount(params, session, socket) do
    %{"language" => language} = session

    socket = socket
    |> assign(language: language)
    |> assign(id: socket.id)
    |> assign(recipe: query_recipe(params, language))
    |> prepare_form()
    |> assign(edit_ingredients: [])
    |> assign(edit_instructions: [])

    {:ok, socket}
  end

  defp prepare_form(socket) do
    socket
    |> assign(edit_title: socket.assigns.recipe.translations == [])
  end

  def handle_event("edit-title", _attrs, socket) do
    {:noreply, socket |> assign(edit_title: true)}
  end

  def handle_info({:update_ingredients, %{ingredients: ingredients}}, socket) do
    language = socket.assigns.language

    change_attrs = %{ingredients: ingredients, language: language}

    {:ok, recipe} = Recipes.update_recipe(socket.assigns.recipe, change_attrs)

    recipe =
      Recipes.get_recipe!(recipe.id)
      |> Recipes.translate(language)

    {:noreply, socket |> assign(recipe: recipe)}
  end

  def handle_info({:cancel_translation, _translatable}, socket) do
    {:noreply, socket |> assign(edit_title: false)}
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
     |> handle_translation_updates(translatable)
     |> assign(recipe: updated_recipe |> Recipes.translate(socket.assigns.language))
    }
  end

  defp handle_translation_updates(socket, %Recipe{} = _translatable) do
    socket
    |> assign(edit_title: false)
  end

  defp handle_translation_updates(socket, _translatable) do
    socket
  end
end
