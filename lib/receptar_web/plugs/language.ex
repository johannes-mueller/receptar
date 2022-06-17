defmodule ReceptarWeb.Plugs.Language do
  use ReceptarWeb, :controller
  import Plug.Conn

  def init(_default), do: ReceptarWeb.Cldr.default_locale.language

  def call(%Plug.Conn{params: %{"language" => language}} = conn, _default) do
    put_session(conn, "language", language)
    |> assign(:language, language)
  end

  def call(conn, default) do
    language = get_session(conn, "language") || default
    put_session(conn, "language", language)
    |> assign(:language, language)
  end
end
