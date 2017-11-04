defmodule StatusMonitor.Server do
  use GenServer
  require Logger

  def start_link do
    Logger.info "Starting Status Monitor GenServer #{__MODULE__}"
    GenServer.start_link(__MODULE__, %{}, name: StatusMonitor.Server)
  end

  def init(%{}) do
    Logger.info "Starting Status Monitor GenServer #{DateTime.utc_now}"
    led_mapping = %{
      "0" => ["api_gateway", "Apothecary"],
      "1" => ["BCI_Services", "Bouncah"],
      "2" => ["Delorean", "feature_toggles"],
      "3" => ["norman", "patient_log"],
      "4" => ["Patients", "postmaster"],
      "5" => ["referrals", "salk"],
      "6" => ["snowflake", "staff"],
      "7" => ["takotsubo"]
    }
    delay = 5 * 60 * 1000 # 5 minutes

    send(self(), :wait_for_wifi)
    {:ok, %{ led_mapping: led_mapping, delay: delay }}
  end

  def handle_info(:wait_for_wifi, state) do
    # IO.inspect Nerves.NetworkInterface.status("wlan0")
    # IO.inspect [:inet.getif(), has_non_loopback_ip?()]
    if has_non_loopback_ip?() do
      send(self(), :run_ntp)
    else
      Process.send_after(self(), :wait_for_wifi, 1000)
    end
    # case Nerves.NetworkInterface.status("wlan0") do
    #   {:ok, %{is_up: true, is_running: true}} -> send(self(), :run_ntp)
    #   _ -> Process.send_after(self(), :wait_for_wifi, 1000)
    # end
    {:noreply, state}
  end

  def handle_info(:run_ntp, state) do
    IO.inspect :run_ntp
    # nerves_ntp starts before our wifi to rerun it now
    System.cmd("/usr/sbin/ntpd", ["-n", "-q", "-p", "0.pool.ntp.org", "-p", "1.pool.ntp.org", "-p", "2.pool.ntp.org", "-p", "3.pool.ntp.org"])
    send(self(), :update_status)
    {:noreply, state}
  end

  def handle_info(:update_status, %{ led_mapping: led_mapping, delay: delay }=state) do
    Logger.info "Status Monitor fetching new status"

    status = StatusMonitor.Rollbar.fetch_status()
    GenServer.cast(self(), :draw)
    schedule_status_check(delay)
    Logger.info "Status Monitor got new statuses"
    {:noreply, %{ led_mapping: led_mapping, delay: delay, status: status }}
  end

  def handle_cast(:draw, %{led_mapping: led_mapping, status: status}=state) do
    StatusMonitor.Rollbar.draw(led_mapping, status)
    {:noreply, state}
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
