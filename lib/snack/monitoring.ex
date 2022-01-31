defmodule Snack.Monitoring do
  @moduledoc """
  The Monitoring context.
  """

  import Ecto.Query, warn: false
  alias Snack.Repo

  alias Snack.Monitoring.Url


  @doc """
  Returns the list of urls.

  ## Examples

      iex> list_urls()
      [%Url{}, ...]

  """
  def list_urls do
    Repo.all(Url)
  end

  @doc """
  Gets a single url.

  Raises `Ecto.NoResultsError` if the Url does not exist.

  ## Examples

      iex> get_url!(123)
      %Url{}

      iex> get_url!(456)
      ** (Ecto.NoResultsError)

  """
  def get_url!(id), do: Repo.get!(Url, id)

  @doc """
  Creates a url.

  ## Examples

      iex> create_url(%{field: value})
      {:ok, %Url{}}

      iex> create_url(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_url(attrs \\ %{}) do
    %Url{}
    |> Url.changeset(attrs)
    |> Repo.insert()
  end

  def create_url_with_user(attrs \\ %{}, conn) do
    maybe_user = Guardian.Plug.current_resource(conn)
    attrs2 = Map.put(attrs , "user_id" , maybe_user.id)
    %Url{}
    |> Url.changeset(attrs2)
    |> Repo.insert()
  end

  def get_urls(id) do
      Repo.query(
      """
      for url in urls
      filter url.user_id=="#{id}"
      return keep(url , "link","threshold" , "_key")
      """
    )
  end

#  def get_urls(conn) do
#    maybe_user = Guardian.Plug.current_resource(conn)
#    ArangoXEcto.aql_query(Repo,
#      """
#      for url in urls
#      filter url.user_id=="#{maybe_user.id}"
#      return keep(url , "link","threshold" , "_key")
#      """
#    )
#  end
#
  @doc """
  Updates a url.

  ## Examples

      iex> update_url(url, %{field: new_value})
      {:ok, %Url{}}

      iex> update_url(url, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_url(%Url{} = url, attrs) do
    url
    |> Url.changeset(attrs)
    |> Repo.update()
  end

  def update_url_counter(url,delay) do
      Repo.query(
      """
        let url = (for u in urls
        filter u._key =="#{url}"
        return keep(u , "_key","updated_at","errors_counter")
        )[0]
        let updated_time = DATE_TIMESTAMP(url.updated_at)
        let now_time = date_iso8601(date_now())
        let obj = now_time - updated_time < #{delay} ?
        [{
        "_key":url._key , "errors_counter": url.errors_counter + 1 , "updated_at": now_time
        }]
        :
        [{
        "_key":url._key ,
        "errors_counter": 0,
        "updated_at": now_time
        }]
        for o in obj
        update o in urls
      """
      )
  end

  @doc """
  Deletes a url.

  ## Examples

      iex> delete_url(url)
      {:ok, %Url{}}

      iex> delete_url(url)
      {:error, %Ecto.Changeset{}}

  """
  def delete_url(%Url{} = url) do
    Repo.delete(url)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking url changes.

  ## Examples

      iex> change_url(url)
      %Ecto.Changeset{data: %Url{}}

  """
  def change_url(%Url{} = url, attrs \\ %{}) do
    Url.changeset(url, attrs)
  end

  alias Snack.Monitoring.Log

  @doc """
  Returns the list of logs.

  ## Examples

      iex> list_logs()
      [%Log{}, ...]

  """
  def list_logs do
    Repo.all(Log)
  end

  @doc """
  Gets a single log.

  Raises `Ecto.NoResultsError` if the Log does not exist.

  ## Examples

      iex> get_log!(123)
      %Log{}

      iex> get_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_log!(id), do: Repo.get!(Log, id)

  def get_urls_log(id) do
    [hd|_ta] = Repo.query(
      """
      let url = (
      for url in urls
      filter url._key=="#{id}"
      return url
      )[0]

      let logs = (
      for log in logs
      filter log.url_id=="#{id}"
      return log
      )
      return {id: url._key , url: url.link , logs: logs}
      """
    )
    hd
  end

  def get_urls_today_log(id) do
    [hd|_ta] = Repo.query(
      """
      let url = (
      for url in urls
      filter url._key=="#{id}"
      return url
      )[0]

      let success = (
      for log in logs
      filter log.url_id=="#{id}" and DATE_ISO8601(log.inserted_at)>DATE_ADD(DATE_NOW(), -1, "day") and log.status==true
      return log
      )
      let failures = (
      for log in logs
      filter log.url_id=="#{id}" and DATE_ISO8601(log.inserted_at)>DATE_ADD(DATE_NOW(), -1, "day") and log.status==false
      return log
      )
      return {id: url._key , url: url.link , suc: count(success) , fail: count(failures)}
      """
    )
    hd
  end



  @doc """
  Creates a log.

  ## Examples

      iex> create_log(%{field: value})
      {:ok, %Log{}}

      iex> create_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_log(attrs \\ %{}) do
    %Log{}
    |> Log.changeset(attrs)
    |> Repo.insert()

  end

  @doc """
  Updates a log.

  ## Examples

      iex> update_log(log, %{field: new_value})
      {:ok, %Log{}}

      iex> update_log(log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_log(%Log{} = log, attrs) do
    log
    |> Log.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a log.

  ## Examples

      iex> delete_log(log)
      {:ok, %Log{}}

      iex> delete_log(log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_log(%Log{} = log) do
    Repo.delete(log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking log changes.

  ## Examples

      iex> change_log(log)
      %Ecto.Changeset{data: %Log{}}

  """
  def change_log(%Log{} = log, attrs \\ %{}) do
    Log.changeset(log, attrs)
  end

  alias Snack.Monitoring.Alert

  @doc """
  Returns the list of alerts.

  ## Examples

      iex> list_alerts()
      [%Alert{}, ...]

  """
  def list_alerts do
    Repo.all(Alert)
  end

  @doc """
  Gets a single alert.

  Raises `Ecto.NoResultsError` if the Alert does not exist.

  ## Examples

      iex> get_alert!(123)
      %Alert{}

      iex> get_alert!(456)
      ** (Ecto.NoResultsError)

  """
  def get_alert!(id), do: Repo.get!(Alert, id)

  def get_alert_by_user(id) do
    Repo.query(
      """
      for alert in alerts
      for url in urls
      filter alert.url_id == url._key
      filter url.user_id == "#{id}"
      return {alert: keep(alert, "inserted_at") ,url: keep(url, "link" , "threshold")}
      """
    )
  end
  @doc """
  Creates a alert.

  ## Examples

      iex> create_alert(%{field: value})
      {:ok, %Alert{}}

      iex> create_alert(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_alert(attrs \\ %{}) do
    %Alert{}
    |> Alert.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a alert.

  ## Examples

      iex> update_alert(alert, %{field: new_value})
      {:ok, %Alert{}}

      iex> update_alert(alert, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_alert(%Alert{} = alert, attrs) do
    alert
    |> Alert.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a alert.

  ## Examples

      iex> delete_alert(alert)
      {:ok, %Alert{}}

      iex> delete_alert(alert)
      {:error, %Ecto.Changeset{}}

  """
  def delete_alert(%Alert{} = alert) do
    Repo.delete(alert)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking alert changes.

  ## Examples

      iex> change_alert(alert)
      %Ecto.Changeset{data: %Alert{}}

  """
  def change_alert(%Alert{} = alert, attrs \\ %{}) do
    Alert.changeset(alert, attrs)
  end
end
