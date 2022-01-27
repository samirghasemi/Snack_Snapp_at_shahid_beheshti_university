defmodule Snack.Monitoring.Url do
  use ArangoXEcto.Schema
  import Ecto.Changeset

  schema "urls" do
    field :user_id, :string
    field :link, :string
    field :thereshold, :integer

    timestamps()
  end

  @doc false
  def changeset(url, attrs) do
    url
    |> cast(attrs, [:user_id , :link, :thereshold])
    |> validate_required([:user_id , :link, :thereshold])
  end
end
