defmodule Snack.Accounts.ErrorHandler do
    import Plug.Conn
    use SnackWeb, :controller

    def auth_error(conn, {type, _reason}, _opts) do
      body = Jason.encode!(%{error: to_string(type)})
      send_resp(conn, 401, body)
    end

end