defmodule Snack.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key false

  schema "users" do
    field :id, :string
    field :username, :string , unique: true
    field :password, :string
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username , :password])
    |> validate_required([:username , :password])
    |> put_password_hash()
  end
  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password: Pbkdf2.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end
