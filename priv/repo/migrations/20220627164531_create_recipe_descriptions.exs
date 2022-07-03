defmodule Receptar.Repo.Migrations.CreateRecipeDescriptions do
  use Ecto.Migration

  def change do
    create table(:recipe_descriptions) do
      add :recipe_id, references(:recipes, on_delete: :delete_all)

      timestamps()
    end

    create index(:recipe_descriptions, [:recipe_id])

    alter table(:translations) do
      add :recipe_description_id, references(:recipe_descriptions, on_delete: :delete_all)
    end

    create index(
      :translations, [
	:substance_id,
	:recipe_id,
	:unit_id,
	:instruction_id,
	:recipe_description_id
      ]
    )
  end
end
