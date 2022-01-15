defmodule ReceptarWeb.UserRegistrationControllerTest do
  use ReceptarWeb.ConnCase, async: true

  import Receptar.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page if admin user is authenticated", %{conn: conn} do
      conn =
	conn
	|> log_in_user(admin_fixture())
	|> get(Routes.user_registration_path(conn, :new))

      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "Log in</a>"
      assert response =~ "User has admin rights"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn =
	conn
	|> log_in_user(user_fixture())
	|> get(Routes.user_registration_path(conn, :new))

      assert redirected_to(conn) == "/"
    end

    test "redirects to log in if no user authenticated", %{conn: conn} do
      user_fixture()
      conn = get(conn, Routes.user_registration_path(conn, :new))

      assert redirected_to(conn) == "/users/log_in"
    end

    test "does not redirect if no user is registered", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))

      assert html_response(conn, 200)
    end
  end

  describe "POST /users/register" do
    @tag :capture_log

    test "redirects to log in if no user authenticated", %{conn: conn} do
      admin_fixture()
      conn = get(conn, Routes.user_registration_path(conn, :create))

      assert redirected_to(conn) == "/users/log_in"
    end

    test "redirects to start if no admin user authenticated", %{conn: conn} do
      conn =
	conn
	|> log_in_user(user_fixture())
	|> get(Routes.user_registration_path(conn, :create))

      assert redirected_to(conn) == "/"
    end

    test "creates account and logs the user in if no user is registered", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
              "user" => Map.put(valid_user_attributes(email: email), :is_admin, true)
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ email
      assert response =~ "Settings</a>"
      assert response =~ "Log out</a>"
    end

    test "creates account and lets admin user logged in", %{conn: conn} do
      email = unique_user_email()

      user = admin_fixture()
      conn =
	conn
        |> log_in_user(user)
        |> post(Routes.user_registration_path(conn, :create), %{
            "user" => valid_user_attributes(email: email)
		})
	|> ReceptarWeb.UserAuth.fetch_current_user(%{})

      assert conn.assigns[:current_user] == user
      assert Receptar.Accounts.get_user_by_email(email)
      assert redirected_to(conn) == "/"
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => "with spaces", "password" => "too short"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
    end

    test "renders error if first user is no admin user", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => valid_user_attributes(email: email)
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "User must be admin as no other admin user is registered"
    end

  end
end
