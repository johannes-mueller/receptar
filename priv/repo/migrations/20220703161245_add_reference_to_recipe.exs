defmodule Receptar.Repo.Migrations.AddReferenceToRecipe do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add :reference, :string
    end
  end
end
