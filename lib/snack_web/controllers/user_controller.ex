defmodule SnackWeb.UserController do
  use SnackWeb, :controller

  alias Snack.Accounts
  alias Snack.Accounts.User

  action_fallback SnackWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def sign_up(conn, %{"user" => user_params}) do
    IO.inspect user_params
    case Accounts.create_user(user_params) do
      {:ok, %User{} = user} ->
        conn
        |> put_status(:created)
        |> render("show.json", user: user)
      {:error, :username_has_been_taken} ->
        {:error, :username_has_been_taken}
    end
  end

  def sign_in(conn, %{"user" => %{"username" => username , "password"=> password}})do
    case Accounts.token_sign_in(username, password) do
      {:ok , token , _claims} ->
        conn
        |> render("jwt.json" , jwt: token)
      _ ->
        {:error , :unauthorized}
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
