defmodule SnackWeb.LogController do
  use SnackWeb, :controller

  alias Snack.Monitoring
  alias Snack.Monitoring.Log

  action_fallback SnackWeb.FallbackController

  def index(conn, _params) do
    logs = Monitoring.list_logs()
    render(conn, "index.json", logs: logs)
  end

  def create(conn, %{"log" => log_params}) do
    with {:ok, %Log{} = log} <- Monitoring.create_log(log_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.log_path(conn, :show, log))
      |> render("show.json", log: log)
    end
  end

  def show(conn, %{"id" => id}) do
    log = Monitoring.get_log!(id)
    render(conn, "show.json", log: log)
  end

  def update(conn, %{"id" => id, "log" => log_params}) do
    log = Monitoring.get_log!(id)

    with {:ok, %Log{} = log} <- Monitoring.update_log(log, log_params) do
      render(conn, "show.json", log: log)
    end
  end

  def delete(conn, %{"id" => id}) do
    log = Monitoring.get_log!(id)

    with {:ok, %Log{}} <- Monitoring.delete_log(log) do
      send_resp(conn, :no_content, "")
    end
  end
end
