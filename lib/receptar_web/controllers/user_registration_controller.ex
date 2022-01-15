defmodule ReceptarWeb.UserRegistrationController do
  use ReceptarWeb, :controller

  alias Receptar.Accounts
  alias Receptar.Accounts.User
  alias ReceptarWeb.UserAuth

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :edit, &1)
          )

          conn
          |> put_flash(:info, "User created successfully.")
	  |> redirect_to_start_or_login(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  defp redirect_to_start_or_login(%{assigns: %{current_user: nil}} = conn, user) do
    UserAuth.log_in_user(conn, user)
  end
  defp redirect_to_start_or_login(conn, _user) do
    redirect(conn, to: "/")
  end
end
