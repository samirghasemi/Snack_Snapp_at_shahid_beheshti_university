defmodule Snack.Server do
  @moduledoc false
  use GenServer
  alias Snack.Monitoring
  @deley 30000
  #  @token  "c1qjlt2ad3ibhunppbi0"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(state) do
    Process.send(__MODULE__, {:update_live_data}, [])
    state = %{}
    {:ok, state}
  end

  def get_live_data() do
    GenServer.call(__MODULE__, {:live_data})
  end

  def handle_info({:update_live_data}, state) do
    urls = Monitoring.list_urls()
    for url <- urls do
      data = case HTTPoison.get(url.link) do
        {:ok, %{status_code: status_code} = params}->
          cond do
            div(status_code,100)==2 ->
              IO.inspect("#{url.link}---------------------######1######-----------------------")
              Monitoring.create_log(%{"url_id" => url.id , "status_code" => "#{status_code}" , "status" => true})
            true ->
              IO.inspect("#{url.link}---------------------######2######-----------------------")
              Monitoring.create_log(%{"url_id" => url.id , "status_code" => "#{status_code}" , "status" => false})
              Monitoring.update_url_counter(url.id , @deley)
              cnt = url.errors_counter
              cnt = cnt+1
              if rem(cnt , url.threshold) == 0 do
                Monitoring.create_alert(%{url_id: url.id})
                IO.inspect("#{url.link}---------------------######3######-----------------------")
              end
          end
        {:error, _} ->
          IO.inspect("#{url.link}---------------------######4######-----------------------")
          Monitoring.create_log(%{"url_id" => url.id , "status_code" => "0" , "status" => false})
          cnt = url.errors_counter
          cnt = cnt+1
          Monitoring.update_url_counter(url.id , @deley)
          if rem(cnt , url.threshold) == 0 do
            Monitoring.create_alert(%{url_id: url.id})
          end
      end
    end
    update_live_data_schedule()
    {:noreply, Map.put(state, :streams_all, nil)}
  end

  def handle_call({:live_data}, _from, state) do
    {:reply, state}
  end

  defp update_live_data_schedule() do
    Process.send_after(__MODULE__, {:update_live_data}, @deley)
  end
  def get_all_streams_from_server() do

  end

end
