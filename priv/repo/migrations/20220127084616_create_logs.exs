defmodule Snack.Repo.Migrations.CreateLogs do
  use Ecto.Migration

  def change do
    create table(:logs) do
      add :url_id, :string

      timestamps()
    end
  end
end
