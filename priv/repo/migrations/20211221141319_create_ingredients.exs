defmodule Receptar.Repo.Migrations.CreateIngredients do
  use Ecto.Migration

  def change do
    create table(:ingredients) do
      add :number, :integer
      add :amount, :decimal
      add :substance_id, references(:substances, on_delete: :nothing)
      add :unit_id, references(:units, on_delete: :nothing)
      add :recipe_id, references(:recipes, on_delete: :delete_all)

      timestamps()
    end
  end
end
