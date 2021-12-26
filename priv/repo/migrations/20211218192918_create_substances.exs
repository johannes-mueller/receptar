defmodule Receptar.Repo.Migrations.CreateSubstances do
  use Ecto.Migration

  def change do
    create table(:substances) do
      add :meat, :boolean
      add :animal, :boolean
      timestamps()
    end
  end
end
