defmodule Snack.Monitoring.Url do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "urls" do
    field :id, :string
    field :user_id, :string
    field :link, :string
    field :threshold, :integer
    field :errors_counter, :integer , default: 0


    timestamps()
  end

  @doc false
  def changeset(url, attrs) do
    url
    |> cast(attrs, [:user_id , :link, :threshold , :errors_counter])
    |> validate_required([:user_id , :link, :threshold])
  end
end
