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

  def render("showby.json", %{alerts: alerts}) do
    %{data: render_many(alerts, AlertView, "alertby.json")}
  end

  def render("alert.json", %{alert: alert}) do
    %{
      id: alert.id,
      url_id: alert.url_id
    }
  end

  def render("alertby.json", %{alert: alert}) do
    IO.inspect alert
    %{
      url_link: alert.url.link,
      url_threshold: alert.url.threshold,
      alert_time: alert.alert.inserted_at
    }
  end
end
