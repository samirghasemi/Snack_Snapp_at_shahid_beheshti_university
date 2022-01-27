defmodule SnackWeb.AlertController do
  use SnackWeb, :controller

  alias Snack.Monitoring
  alias Snack.Monitoring.Alert

  action_fallback SnackWeb.FallbackController

  def index(conn, _params) do
    alerts = Monitoring.list_alerts()
    render(conn, "index.json", alerts: alerts)
  end

  def create(conn, %{"alert" => alert_params}) do
    with {:ok, %Alert{} = alert} <- Monitoring.create_alert(alert_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.alert_path(conn, :show, alert))
      |> render("show.json", alert: alert)
    end
  end

  def show(conn, %{"id" => id}) do
    alert = Monitoring.get_alert!(id)
    render(conn, "show.json", alert: alert)
  end

  def update(conn, %{"id" => id, "alert" => alert_params}) do
    alert = Monitoring.get_alert!(id)

    with {:ok, %Alert{} = alert} <- Monitoring.update_alert(alert, alert_params) do
      render(conn, "show.json", alert: alert)
    end
  end

  def delete(conn, %{"id" => id}) do
    alert = Monitoring.get_alert!(id)

    with {:ok, %Alert{}} <- Monitoring.delete_alert(alert) do
      send_resp(conn, :no_content, "")
    end
  end
end
