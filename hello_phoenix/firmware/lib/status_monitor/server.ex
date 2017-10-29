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
    delay = 60 * 1000 # 1 minute
    schedule_status_check(20_000)
    {:ok, %{ led_mapping: led_mapping, delay: delay }}
  end

  def handle_info(:update_status, %{ led_mapping: led_mapping, delay: delay }=state) do
    Logger.info "Status Monitor GenServer is ready to do its work #{DateTime.utc_now}"
    IO.inspect state
    # nerves_ntp starts before our wifi to rerun it now
    System.cmd("/usr/sbin/ntpd", ["-n", "-q", "-p", "0.pool.ntp.org", "-p", "1.pool.ntp.org", "-p", "2.pool.ntp.org", "-p", "3.pool.ntp.org"])

    status = StatusMonitor.Rollbar.fetch_status()
    GenServer.cast(self(), :draw)
    schedule_status_check(delay)
    {:noreply, %{ led_mapping: led_mapping, delay: delay, status: status }}
  end

  def handle_cast(:draw, %{led_mapping: led_mapping, status: status}=state) do
    StatusMonitor.Rollbar.draw(led_mapping, status)
    {:noreply, state}
  end

  def handle_call({:get_status}, _, %{ status: status } = state) do
    IO.inspect [:get_status, status, state]
    {:reply, status, state}
  end

  def handle_call({:get_led_mapping}, _, %{ led_mapping: led_mapping } = state) do
    IO.inspect [:get_status, led_mapping, state]
    {:reply, led_mapping, state}
  end

  def handle_call({:set_led_mapping, led_mapping}, _, state) do
    new_state = Map.put(state, :led_mapping, led_mapping)
    IO.inspect [:set_led_mapping, new_state]
    {:reply, led_mapping, new_state}
  end

  defp schedule_status_check(delay) do
    Process.send_after(self(), :update_status, delay)
  end

end
