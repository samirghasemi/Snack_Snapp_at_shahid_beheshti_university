defmodule SnackWeb.UrlController do
  use SnackWeb, :controller

  alias Snack.Monitoring
  alias Snack.Monitoring.Url

  action_fallback SnackWeb.FallbackController

  def index(conn, _params) do
    urls = Monitoring.list_urls()
    render(conn, "index.json", urls: urls)
  end

  def create(conn, %{"url" => url_params}) do
    with {:ok, %Url{} = url} <- Monitoring.create_url(url_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.url_path(conn, :show, url))
      |> render("show.json", url: url)
    end
  end

  def show(conn, %{"id" => id}) do
    url = Monitoring.get_url!(id)
    render(conn, "show.json", url: url)
  end

  def update(conn, %{"id" => id, "url" => url_params}) do
    url = Monitoring.get_url!(id)

    with {:ok, %Url{} = url} <- Monitoring.update_url(url, url_params) do
      render(conn, "show.json", url: url)
    end
  end

  def delete(conn, %{"id" => id}) do
    url = Monitoring.get_url!(id)

    with {:ok, %Url{}} <- Monitoring.delete_url(url) do
      send_resp(conn, :no_content, "")
    end
  end
end
