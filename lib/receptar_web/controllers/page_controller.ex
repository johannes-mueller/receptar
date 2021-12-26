defmodule ReceptarWeb.PageController do
  use ReceptarWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
