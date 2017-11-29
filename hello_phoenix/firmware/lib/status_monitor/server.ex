defmodule StatusMonitor.Server do
  use GenServer
  require Logger

  def start_link do
    Logger.info "Starting Status Monitor GenServer #{__MODULE__}"
    GenServer.start_link(__MODULE__, %{}, name: StatusMonitor.Server)
  end

  def init(%{}) do
    Logger.info "Starting Status Monitor GenServer #{DateTime.utc_now}"
    delay = 5 * 60 * 1000 # 5 minutes

    send(self(), :update_status)
    {:ok, %{ delay: delay }}
  end

  def handle_info(:update_status, %{ delay: delay } = state) do
    if has_non_loopback_ip?() do
      Logger.info "Status Monitor fetching new status"

      # nerves_ntp starts before our wifi to rerun it now
      System.cmd("/usr/sbin/ntpd", ["-n", "-q", "-p", "0.pool.ntp.org", "-p", "1.pool.ntp.org", "-p", "2.pool.ntp.org", "-p", "3.pool.ntp.org"])

      status = StatusMonitor.Rollbar.fetch_status()
      GenServer.cast(self(), :draw)
      schedule_status_check(delay)
      Logger.info "Status Monitor got new statuses"
      new_state = state
        |> Map.put(:status, status)
        |> Map.put(:last_update, DateTime.utc_now)
      {:noreply, new_state}
    else
      Logger.info "Can't update status because we don't have an IP"
      Process.send_after(self(), :update_status, 1000)
      {:noreply, state}
    end
  end

  def handle_cast(:update_status, state) do
    if has_non_loopback_ip?() do
      Logger.info "Status Monitor fetching new status"

      status = StatusMonitor.Rollbar.fetch_status()
      GenServer.cast(self(), :draw)
      Logger.info "Status Monitor got new statuses"
      new_state = state
        |> Map.put(:status, status)
        |> Map.put(:last_update, DateTime.utc_now)
      {:noreply, new_state}
    else
      Logger.info "Can't update status because we don't have an IP"
      {:noreply, state}
    end
  end

  def handle_cast(:draw, %{led_mapping: led_mapping, status: status}=state) do
    StatusMonitor.Rollbar.draw(led_mapping, status)
    {:noreply, state}
  end

  def handle_cast(:draw, %{status: status}=state) do
    projects_per_led = Enum.count(status) / 8
    |> round
    led_mapping = Enum.map(status, &(&1.name))
    |> Enum.chunk_every(projects_per_led)
    led_mapping = if Enum.count(led_mapping) == 9 do
      last_led = Enum.concat(Enum.at(led_mapping, 7), Enum.at(led_mapping, 8))
      List.replace_at(led_mapping, 7, last_led)
    else
      led_mapping
    end
    StatusMonitor.Rollbar.draw(led_mapping, status)
    new_state = Map.put(state, :led_mapping, led_mapping)
    {:noreply, new_state}
  end

  def handle_call({:get_last_update}, _, %{ last_update: last_update } = state) do
    {:reply, last_update, state}
  end

  def handle_call({:get_status}, _, %{ status: status } = state) do
    {:reply, status, state}
  end

  def handle_call({:get_led_mapping}, _, %{ led_mapping: led_mapping } = state) do
    {:reply, led_mapping, state}
  end

  def handle_call({:set_led_mapping, led_mapping}, _, state) do
    new_state = Map.put(state, :led_mapping, led_mapping)
    {:reply, led_mapping, new_state}
  end

  def handle_call({:get_delay}, _, %{ delay: delay } = state) do
    {:reply, delay, state}
  end

  def handle_call({:set_delay, delay}, _, state) do
    new_state = Map.put(state, :delay, delay)
    {:reply, delay, new_state}
  end

  defp schedule_status_check(delay) do
    Process.send_after(self(), :update_status, delay)
  end

  defp has_non_loopback_ip? do
    case :inet.getif() do
      {:ok, ips} -> has_non_loopback_ip?(ips)
      _ -> false
    end
  end

  defp has_non_loopback_ip?([]) do
    false
  end

  defp has_non_loopback_ip?([{{127, 0, 0, 1}, {0, 0, 0, 0}, {255, 0, 0, 0}} | tail]) do
    has_non_loopback_ip?(tail)
  end

  defp has_non_loopback_ip?([_head | _tail]) do
    true
  end

end
