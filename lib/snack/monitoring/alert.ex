defmodule Snack.Monitoring.Alert do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key false

  schema "alerts" do
    field :id, :string
    field :url_id, :string

    timestamps()
  end

  @doc false
  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:url_id])
    |> validate_required([:url_id])
  end
end
