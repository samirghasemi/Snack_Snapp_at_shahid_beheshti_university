defmodule SnackWeb.AlertControllerTest do
  use SnackWeb.ConnCase

  import Snack.MonitoringFixtures

  alias Snack.Monitoring.Alert

  @create_attrs %{
    url_id: "some url_id"
  }
  @update_attrs %{
    url_id: "some updated url_id"
  }
  @invalid_attrs %{url_id: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all alerts", %{conn: conn} do
      conn = get(conn, Routes.alert_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create alert" do
    test "renders alert when data is valid", %{conn: conn} do
      conn = post(conn, Routes.alert_path(conn, :create), alert: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.alert_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "url_id" => "some url_id"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.alert_path(conn, :create), alert: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update alert" do
    setup [:create_alert]

    test "renders alert when data is valid", %{conn: conn, alert: %Alert{id: id} = alert} do
      conn = put(conn, Routes.alert_path(conn, :update, alert), alert: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.alert_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "url_id" => "some updated url_id"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, alert: alert} do
      conn = put(conn, Routes.alert_path(conn, :update, alert), alert: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete alert" do
    setup [:create_alert]

    test "deletes chosen alert", %{conn: conn, alert: alert} do
      conn = delete(conn, Routes.alert_path(conn, :delete, alert))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.alert_path(conn, :show, alert))
      end
    end
  end

  defp create_alert(_) do
    alert = alert_fixture()
    %{alert: alert}
  end
end
