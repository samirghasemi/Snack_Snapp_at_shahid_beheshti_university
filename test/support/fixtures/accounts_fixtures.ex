defmodule Snack.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snack.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        username: "some username"
      })
      |> Snack.Accounts.create_user()

    user
  end
end
