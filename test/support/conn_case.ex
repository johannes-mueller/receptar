defmodule ReceptarWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ReceptarWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ReceptarWeb.ConnCase

      alias ReceptarWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint ReceptarWeb.Endpoint
    end
  end

  def html_response_stripped(conn, code) do
    Phoenix.ConnTest.html_response(conn, code)
    |> strip_html_code
  end

  def strip_html_code(html) do
    html
    |> String.replace("\n", "")
    |> String.replace("\t", "")
    |> String.replace(~r/> *</, "><")
  end


  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Receptar.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = Receptar.AccountsFixtures.admin_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  def register_and_log_in_non_admin_user(%{conn: conn}) do
    Receptar.AccountsFixtures.admin_fixture()
    user = Receptar.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = Receptar.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  def init_session(conn) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
  end
end
