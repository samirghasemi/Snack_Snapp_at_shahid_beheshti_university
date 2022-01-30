defmodule SnackWeb.UrlView do
  use SnackWeb, :view
  alias SnackWeb.UrlView

  def render("index.json", %{url: url}) do
    %{data: render_many(url, UrlView, "url.json")}
  end

  def render("show.json", %{url: url}) do
    %{data: render_one(url, UrlView, "create.json")}
  end

  def render("create.json", %{url: url} = param) do
    IO.inspect(param)
    %{
      id: url.id,
      link: url.link,
      threshold: url.threshold
    }
  end

  def render("url.json", %{url: %{"_key" => key, "link" => link, "threshold" => threshold}} = url) do
    %{
      id: key,
      link: link,
      threshold: threshold
    }
  end
end
