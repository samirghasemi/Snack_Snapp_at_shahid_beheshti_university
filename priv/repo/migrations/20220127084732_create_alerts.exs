defmodule Snack.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts) do
      add :url_id, :string

      timestamps()
    end
  end
end
