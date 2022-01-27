defmodule Snack.MonitoringFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snack.Monitoring` context.
  """

  @doc """
  Generate a url.
  """
  def url_fixture(attrs \\ %{}) do
    {:ok, url} =
      attrs
      |> Enum.into(%{
        user_id: "some user_id"
      })
      |> Snack.Monitoring.create_url()

    url
  end

  @doc """
  Generate a log.
  """
  def log_fixture(attrs \\ %{}) do
    {:ok, log} =
      attrs
      |> Enum.into(%{
        url_id: "some url_id"
      })
      |> Snack.Monitoring.create_log()

    log
  end

  @doc """
  Generate a alert.
  """
  def alert_fixture(attrs \\ %{}) do
    {:ok, alert} =
      attrs
      |> Enum.into(%{
        url_id: "some url_id"
      })
      |> Snack.Monitoring.create_alert()

    alert
  end
end
