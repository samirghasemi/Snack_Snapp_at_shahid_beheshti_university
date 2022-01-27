defmodule SnackWeb.LogView do
  use SnackWeb, :view
  alias SnackWeb.LogView

  def render("index.json", %{logs: logs}) do
    %{data: render_many(logs, LogView, "log.json")}
  end

  def render("show.json", %{log: log}) do
    %{data: render_one(log, LogView, "log.json")}
  end

  def render("log.json", %{log: log}) do
    %{
      id: log.id,
      url_id: log.url_id
    }
  end
end
