defmodule Receptar.Repo.Migrations.CreateUnits do
  use Ecto.Migration

  def change do
    create table(:units) do

      timestamps()
    end
  end
end
