defmodule Receptar.Repo.Migrations.AddServingsToRecipe do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add :servings, :integer, null: false, default: 2
    end

  end
end
