defmodule SnackWeb.PageController do
  use SnackWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
