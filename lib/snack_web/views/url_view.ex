defmodule SnackWeb.UrlView do
  use SnackWeb, :view
  alias SnackWeb.UrlView

  def render("index.json", %{url: url}) do
    %{data: render_many(url, UrlView, "create.json")}
  end

  def render("create.json", %{url: url} = param) do
    %{
       id: url.id,
       link: url.link,
       threshold: url.threshold
    }
  end

  def render("statistic.json", %{log: log}) do
    %{
      id: log.id,
      link: log.url,
      fail: log.fail,
      suc: log.suc,
    }
  end
end
