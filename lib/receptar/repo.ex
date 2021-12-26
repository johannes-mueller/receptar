defmodule Receptar.Repo do
  use Ecto.Repo,
    otp_app: :receptar,
    adapter: Ecto.Adapters.Postgres
end
