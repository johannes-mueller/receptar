defmodule ReceptarWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use ReceptarWeb, :controller
      use ReceptarWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: ReceptarWeb

      import Plug.Conn
      import ReceptarWeb.Gettext
      alias ReceptarWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/receptar_web/templates",
        namespace: ReceptarWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {ReceptarWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import ReceptarWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import ReceptarWeb.ErrorHelpers
      import ReceptarWeb.Gettext
      alias ReceptarWeb.Router.Helpers, as: Routes

      def tr(:translation_missing) do
	"<span class=\"translation-missing\">" <> gettext("Translation missing") <> "</span>"
	|> raw
      end
      def tr(translated_string), do: translated_string

      def tr_form(:translation_missing), do: ""
      def tr_form(translated_string), do: translated_string

      def idfy(string, id), do: string <> "-#{id}"

      def render_amount(%{amount: amount}) do
	amount
	|> Decimal.to_string(:xsd)
      end

      def render_servings(%{servings: 1}), do: "one serving"
      def render_servings(%{servings: servings}), do: "#{servings} servings"

      def render_tooltip_button(button_data, tooltip) do
	{tooltip_span_class, button_data} = Map.pop(button_data, "outer-class")
	tooltip_span_class = case tooltip_span_class do
			       nil -> "\"tooltipped\""
			       some_class -> "\"tooltipped #{some_class}\""
			     end

	button_attrs =
	  button_data
	|> Enum.reduce(
	  "",
	  fn {name, value}, acc ->
	    acc <> " #{name}=\"#{value}\""
	  end)

	tooltip_span = "<span class=\"tooltip\">#{tooltip}</span>"
	button_string = "<button #{button_attrs}></button>"
	raw "<span class=#{tooltip_span_class}>#{button_string}#{tooltip_span}</span>"
      end

      def render_edit_button_group(item_name, item, target) do
	add = safe_to_string render_tooltip_button(
	  %{
	    "class" => "add-button",
	    "id" => idfy("insert-#{item_name}", item.number),
	    "phx-click" => "insert-#{item_name}",
	    "phx-target" => target,
	    "phx-value-number" => item.number
	  }, "Insert before")
	delete = safe_to_string render_tooltip_button(
	  %{
	    "class" => "delete-button",
	    "id" => idfy("delete-#{item_name}", item.number),
	    "phx-click" => "delete-#{item_name}",
	    "phx-target" => target,
	    "phx-value-number" => item.number
	  }, "Delete")
	push = safe_to_string render_tooltip_button(
	  %{
	    "class" => "down-button",
	    "id" => idfy("push-#{item_name}", item.number),
	    "phx-click" => "push-#{item_name}",
	    "phx-target" =>  target,
	    "phx-value-number" => item.number
	  }, "Move down")
	pull = safe_to_string render_tooltip_button(
	  %{
	    "class" => "up-button",
	    "id" => idfy("pull-#{item_name}", item.number),
	    "phx-click" => "pull-#{item_name}",
	    "phx-target" => target,
	    "phx-value-number" => item.number
	  }, "Move up")

	raw "<div class=\"edit-button-group\">#{add}&nbsp;#{delete}&nbsp;#{push}&nbsp;#{pull}</div>"
      end

      def maybe_add_to_list(number, list) do
	case Integer.parse(number) do
	  :error -> list
	  {i, _remainder} ->
	    if i not in list do
	      [i | list]
	    else
	      list
	    end
	end
      end

      def conn_params_without_language(%Plug.Conn{params: params}) do
	allowed_fields = ["title", "class"]
	Map.filter(params, fn {k, _v} -> k in allowed_fields end)
      end

      def recipe_path(%Receptar.Recipes.Recipe{id: id}), do: "/recipe/#{id}"

    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
