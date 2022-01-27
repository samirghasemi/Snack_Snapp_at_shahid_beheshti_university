defmodule Snack.MonitoringTest do
  use Snack.DataCase

  alias Snack.Monitoring

  describe "urls" do
    alias Snack.Monitoring.Url

    import Snack.MonitoringFixtures

    @invalid_attrs %{user_id: nil}

    test "list_urls/0 returns all urls" do
      url = url_fixture()
      assert Monitoring.list_urls() == [url]
    end

    test "get_url!/1 returns the url with given id" do
      url = url_fixture()
      assert Monitoring.get_url!(url.id) == url
    end

    test "create_url/1 with valid data creates a url" do
      valid_attrs = %{user_id: "some user_id"}

      assert {:ok, %Url{} = url} = Monitoring.create_url(valid_attrs)
      assert url.user_id == "some user_id"
    end

    test "create_url/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Monitoring.create_url(@invalid_attrs)
    end

    test "update_url/2 with valid data updates the url" do
      url = url_fixture()
      update_attrs = %{user_id: "some updated user_id"}

      assert {:ok, %Url{} = url} = Monitoring.update_url(url, update_attrs)
      assert url.user_id == "some updated user_id"
    end

    test "update_url/2 with invalid data returns error changeset" do
      url = url_fixture()
      assert {:error, %Ecto.Changeset{}} = Monitoring.update_url(url, @invalid_attrs)
      assert url == Monitoring.get_url!(url.id)
    end

    test "delete_url/1 deletes the url" do
      url = url_fixture()
      assert {:ok, %Url{}} = Monitoring.delete_url(url)
      assert_raise Ecto.NoResultsError, fn -> Monitoring.get_url!(url.id) end
    end

    test "change_url/1 returns a url changeset" do
      url = url_fixture()
      assert %Ecto.Changeset{} = Monitoring.change_url(url)
    end
  end

  describe "logs" do
    alias Snack.Monitoring.Log

    import Snack.MonitoringFixtures

    @invalid_attrs %{url_id: nil}

    test "list_logs/0 returns all logs" do
      log = log_fixture()
      assert Monitoring.list_logs() == [log]
    end

    test "get_log!/1 returns the log with given id" do
      log = log_fixture()
      assert Monitoring.get_log!(log.id) == log
    end

    test "create_log/1 with valid data creates a log" do
      valid_attrs = %{url_id: "some url_id"}

      assert {:ok, %Log{} = log} = Monitoring.create_log(valid_attrs)
      assert log.url_id == "some url_id"
    end

    test "create_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Monitoring.create_log(@invalid_attrs)
    end

    test "update_log/2 with valid data updates the log" do
      log = log_fixture()
      update_attrs = %{url_id: "some updated url_id"}

      assert {:ok, %Log{} = log} = Monitoring.update_log(log, update_attrs)
      assert log.url_id == "some updated url_id"
    end

    test "update_log/2 with invalid data returns error changeset" do
      log = log_fixture()
      assert {:error, %Ecto.Changeset{}} = Monitoring.update_log(log, @invalid_attrs)
      assert log == Monitoring.get_log!(log.id)
    end

    test "delete_log/1 deletes the log" do
      log = log_fixture()
      assert {:ok, %Log{}} = Monitoring.delete_log(log)
      assert_raise Ecto.NoResultsError, fn -> Monitoring.get_log!(log.id) end
    end

    test "change_log/1 returns a log changeset" do
      log = log_fixture()
      assert %Ecto.Changeset{} = Monitoring.change_log(log)
    end
  end

  describe "alerts" do
    alias Snack.Monitoring.Alert

    import Snack.MonitoringFixtures

    @invalid_attrs %{url_id: nil}

    test "list_alerts/0 returns all alerts" do
      alert = alert_fixture()
      assert Monitoring.list_alerts() == [alert]
    end

    test "get_alert!/1 returns the alert with given id" do
      alert = alert_fixture()
      assert Monitoring.get_alert!(alert.id) == alert
    end

    test "create_alert/1 with valid data creates a alert" do
      valid_attrs = %{url_id: "some url_id"}

      assert {:ok, %Alert{} = alert} = Monitoring.create_alert(valid_attrs)
      assert alert.url_id == "some url_id"
    end

    test "create_alert/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Monitoring.create_alert(@invalid_attrs)
    end

    test "update_alert/2 with valid data updates the alert" do
      alert = alert_fixture()
      update_attrs = %{url_id: "some updated url_id"}

      assert {:ok, %Alert{} = alert} = Monitoring.update_alert(alert, update_attrs)
      assert alert.url_id == "some updated url_id"
    end

    test "update_alert/2 with invalid data returns error changeset" do
      alert = alert_fixture()
      assert {:error, %Ecto.Changeset{}} = Monitoring.update_alert(alert, @invalid_attrs)
      assert alert == Monitoring.get_alert!(alert.id)
    end

    test "delete_alert/1 deletes the alert" do
      alert = alert_fixture()
      assert {:ok, %Alert{}} = Monitoring.delete_alert(alert)
      assert_raise Ecto.NoResultsError, fn -> Monitoring.get_alert!(alert.id) end
    end

    test "change_alert/1 returns a alert changeset" do
      alert = alert_fixture()
      assert %Ecto.Changeset{} = Monitoring.change_alert(alert)
    end
  end
end
