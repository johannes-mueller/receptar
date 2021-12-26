defmodule Receptar.Repo.Migrations.CreateInstructions do
  use Ecto.Migration

  def change do
    create table(:instructions) do
      add :recipe_id, references(:recipes, on_delete: :delete_all)
      add :number, :integer
      timestamps()
    end

    create index(:instructions, [:recipe_id])
  end
end
