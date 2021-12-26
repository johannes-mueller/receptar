defmodule Receptar.Repo.Migrations.CreateRecipes do
  use Ecto.Migration

  def change do
    create table(:recipes) do

      timestamps()
    end
  end
end
