defmodule SnackWeb.AlertView do
  use SnackWeb, :view
  alias SnackWeb.AlertView

  def render("index.json", %{alerts: alerts}) do
    %{data: render_many(alerts, AlertView, "alert.json")}
  end

  def render("show.json", %{alert: alert}) do
    %{data: render_one(alert, AlertView, "alert.json")}
  end

  def render("alert.json", %{alert: alert}) do
    %{
      id: alert.id,
      url_id: alert.url_id
    }
  end
end
