defmodule SnackWeb.UrlController do
  use SnackWeb, :controller

  alias Snack.Monitoring
  alias Snack.Monitoring.Url

  action_fallback SnackWeb.FallbackController

  def index(conn, _params) do
    urls = Monitoring.list_urls()
    render(conn, "index.json", urls: urls)
  end

  def create(conn, %{"url" => url_params} = param) do
    with {:ok, %Url{} = url} <- Monitoring.create_url_with_user(url_params,conn) do
      conn
      |> put_status(:created)
      |> render("show.json", url: url)
    end
  end

  def show(conn, %{"id" => id}) do
    url = Monitoring.get_urls(conn)
    render(conn, "show.json", url: url)
  end

  def list(conn, %{"id" => id}) do

#    with {:ok, res} <- Monitoring.get_urls(conn)do
#      render(conn, "index.json", url: res)
#    end
#    IO.inspect urls

    with {:ok, res} <- Monitoring.get_urls(id)do
      render(conn, "index.json", url: res)
    end
  end

end
