defmodule Snack.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Snack.Repo

  alias Snack.Accounts.User
  alias Snack.Accounts.Guardian

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(%{"username" => username} = attrs \\ %{}) do
    case get_user_by_username(username) do
      {:error, :not_found} ->
        %User{}
        |> User.changeset(attrs)
        |> Repo.insert()
      {:ok, user} ->
        {:error, :username_has_been_taken}
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
  def authenticate_user(username, plain_text_password) do
    query = from u in User, where: u.username == ^username
    case Repo.one(query) do
      nil ->
        Pbkdf2.no_user_verify()
        {:error, :invalid_credentials}
      user ->
        case Pbkdf2.verify_pass(plain_text_password, user.password) do
          true ->
            {:ok, user}
          false ->
            {:error, :invalid_credentials}
        end
    end
  end

  defp get_user_by_username(username) when is_binary(username)do
    aql = """
      for u in users
      filter u.username=="#{username}"
      limit 1
      return u
    """
     case Repo.query(aql) do
      [] ->
        Pbkdf2.no_user_verify()
        {:error, :not_found}
      user ->
        [hd| _ta] = user
        {:ok, hd}
    end
  end

  defp verify_password(password, user) when is_binary(password) do
    if Pbkdf2.verify_pass(password, user.password) do
      {:ok, user}
    else
      {:error, :invalid_password}
    end
  end

  defp user_password_auth(username, password) when is_binary(username) and is_binary(password) do
    with {:ok , user} <- get_user_by_username(username),
         do: verify_password(password , user)
  end

  def token_sign_in(username , password) do
    case user_password_auth(username , password) do
      {:ok , user} ->
        Guardian.encode_and_sign(user)
      _ ->
        {:error , :unauthorized}
    end
  end


end
