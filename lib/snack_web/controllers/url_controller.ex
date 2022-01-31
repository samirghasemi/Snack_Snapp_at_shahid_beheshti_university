defmodule SnackWeb.UrlController do
  use SnackWeb, :controller

  alias Snack.Monitoring
  alias Snack.Monitoring.Url

  action_fallback SnackWeb.FallbackController

  def create(conn, %{"url" => url_params} = param) do
    with {:ok, %Url{} = url} <- Monitoring.create_url_with_user(url_params,conn) do
      IO.inspect(url)

      conn
      |> put_status(:created)
      |> render("create.json", url: url)
    end
  end

  def list(conn, %{"id" => id}) do
    url = Monitoring.get_urls(id)
    render(conn, "index.json", url: url)
  end

  def statistic(conn, %{"id" => id}) do
      log = Monitoring.get_urls_today_log(id)
      render(conn, "statistic.json", log: log)
  end

end
