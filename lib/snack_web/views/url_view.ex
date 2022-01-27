defmodule SnackWeb.UrlView do
  use SnackWeb, :view
  alias SnackWeb.UrlView

  def render("index.json", %{urls: urls}) do
    %{data: render_many(urls, UrlView, "url.json")}
  end

  def render("show.json", %{url: url}) do
    %{data: render_one(url, UrlView, "url.json")}
  end

  def render("url.json", %{url: url}) do
    %{
      id: url.id,
      user_id: url.user_id
    }
  end
end
