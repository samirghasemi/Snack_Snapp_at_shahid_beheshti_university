defmodule Snack.Repo.Migrations.CreateUrls do
  use Ecto.Migration

  def change do
    create table(:urls) do
      add :user_id, :string

      timestamps()
    end
  end
end
