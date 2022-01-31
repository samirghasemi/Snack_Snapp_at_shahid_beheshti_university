defmodule SnackWeb.AlertController do
  use SnackWeb, :controller

  alias Snack.Monitoring
  alias Snack.Monitoring.Alert

  action_fallback SnackWeb.FallbackController

  def index(conn, _params) do
    alerts = Monitoring.list_alerts()
    render(conn, "index.json", alerts: alerts)
  end

  def index(conn, %{"id" => id}) do
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

  def show_by_id(conn, %{"id" => id}) do
    alerts = Monitoring.get_alert_by_user(id)
    render(conn, "showby.json", alerts: alerts)
  end

end
