defmodule Snack.Monitoring.Log do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key false

  schema "logs" do
    field :id, :string
    field :url_id, :string
    field :status, :boolean
    field :status_code, :string
    timestamps()
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [:url_id , :status , :status_code])
    |> validate_required([:url_id , :status , :status_code])
  end
end
