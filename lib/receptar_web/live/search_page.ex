defmodule ReceptarWeb.SearchPage do
  use ReceptarWeb, :live_view

  alias Receptar.Recipes
  alias Receptar.Substances

  def mount(params, session, socket) do
    language = session["language"]
    params = sanitize_parameters(params)

    {
      :ok,
      socket
      |> assign(language: language)
      |> assign_recipes(params)
      |> assign(search_params: params)
      |> assign_shown_substances()
    }
  end

  def handle_params(params, _uri, socket) do
     params = sanitize_parameters(params)
    {
      :noreply,
      socket
      |> assign_selected_shown_substances(params)
      |> assign_recipes(params)
      |> assign(search_params: params)
    }
  end

  def handle_event("form-change", params, socket) do
    params = sanitize_parameters(params)
    {
      :noreply,
      socket
      |> push_patch(to: Routes.live_path(socket, ReceptarWeb.SearchPage, params))
    }
  end

  def handle_event("search-substance", %{"search_string" => search_string}, socket) do
    shown_substances =
      socket.assigns.shown_substances
      |> Enum.filter(fn {_, selected} -> selected end)

    shown_substance_ids =
      shown_substances
      |> Enum.map(fn {s, _} -> s.id end)

    newly_shown_substances =
      query_newly_shown_substances(search_string, socket.assigns.language)
      |> Enum.filter(fn {s, _} -> s.id not in shown_substance_ids end)

    {
      :noreply,
      socket
      |> assign(shown_substances: shown_substances ++ newly_shown_substances)
    }
  end

  defp assign_recipes(socket, params) do
    language = socket.assigns.language

    recipes =
      params
      |> Recipes.search(language)
      |> Recipes.translate(language)

    socket
    |> assign(recipes: recipes)
  end

  defp search_result_title(0), do: gettext("No recipes found.")
  defp search_result_title(1), do: gettext("One recipe found.")
  defp search_result_title(number), do: gettext("%{number} recipes found.", number: number)

  defp assign_shown_substances(socket) do
    shown_substances =
      socket.assigns.search_params
      |> Map.get("substance", [])
      |> Enum.map(&Substances.get/1)
      |> Enum.filter(& &1)
      |> Enum.map(& Substances.translate(&1, socket.assigns.language))
      |> Enum.map(& {&1, true})

    socket |> assign(shown_substances: shown_substances)
  end

  defp assign_selected_shown_substances(socket, %{"substance" => selected}) do
    shown_substances =
      socket.assigns.shown_substances
      |> Enum.map(fn {s, _} -> {s, s.id in selected} end)

    socket |> assign(shown_substances: shown_substances)
  end

  defp assign_selected_shown_substances(socket, %{}) do
    all_unchecked =
      socket.assigns.shown_substances
      |> Enum.map(fn {s, _} -> {s, false} end)

    socket
    |> assign(shown_substances: all_unchecked)
  end

  defp query_newly_shown_substances("" = _search_string, _language), do: []

  defp query_newly_shown_substances(search_string, language) do
    Substances.search(search_string, language)
    |> Substances.translate(language)
    |> Enum.map(& {&1, false})
  end

  defp sanitize_parameters(%{} = params) do
    params
    |> Enum.filter(fn {k, _} -> k != "_target" end)
    |> Enum.filter(fn {k, v} -> not (k == "class" and v == "all") end)
    |> Enum.map(&sanitize_parameters/1)
    |> Enum.into(%{})
  end

  defp sanitize_parameters({"substance", substance_list}) do
    substance_list = substance_list
    |> enforce_list
    |> Enum.filter(&only_single_values/1)
    |> Enum.map(&Integer.parse/1)
    |> Enum.map(fn
      {i, _remainder} -> i
      :error -> :error
    end)
    |> Enum.filter(&(&1 != :error))

    {"substance", substance_list}
  end

  defp sanitize_parameters({some_key, "true"}), do: {some_key, true}
  defp sanitize_parameters({some_key, "false"}), do: {some_key, false}
  defp sanitize_parameters(any_other_parameter), do: any_other_parameter

  defp only_single_values({_some_key, _some_value}), do: false
  defp only_single_values(%{}), do: false
  defp only_single_values(_some_value), do: true

  defp enforce_list([_|_] = list), do: list
  defp enforce_list(nolist), do: [nolist]

end
