defmodule Snack.Monitoring.Log do
  use ArangoXEcto.Schema
  import Ecto.Changeset

  schema "logs" do
    field :url_id, :string
    field :body, :string
    field :status_code, :string
    timestamps()
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [:url_id , :body , :status_code])
    |> validate_required([:url_id , :body , :status_code])
  end
end
