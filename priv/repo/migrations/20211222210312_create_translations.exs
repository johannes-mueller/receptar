defmodule Receptar.Repo.Migrations.CreateTranslations do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :content, :string
      add :language, :string
      add :substance_id, references(:substances, on_delete: :delete_all)
      add :recipe_id, references(:recipes, on_delete: :delete_all)
      add :unit_id, references(:units, on_delete: :nothing)
      add :instruction_id, references(:instructions, on_delete: :delete_all)

      timestamps()
    end

    create index(:translations, [:substance_id, :recipe_id, :unit_id, :instruction_id])
  end
end
