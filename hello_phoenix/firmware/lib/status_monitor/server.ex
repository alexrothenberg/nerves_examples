defmodule StatusMonitor.Server do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Logger.info "Starting Status Monitor GenServer #{DateTime.utc_now}"
    schedule_status_check(20_000)
    {:ok, state}
  end

  def handle_info(:update_status, state) do
    Logger.info "Status Monitor GenServer is ready to do its work #{DateTime.utc_now}"
    # nerves_ntp starts before our wifi to rerun it now
    System.cmd("/usr/sbin/ntpd", ["-n", "-q", "-p", "0.pool.ntp.org", "-p", "1.pool.ntp.org", "-p", "2.pool.ntp.org", "-p", "3.pool.ntp.org"])

    StatusMonitor.Rollbar.update_status
    # delay = 2 * 60 * 60 * 1000 # 2 hours
    delay = 60 * 1000 # 1 minute
    schedule_status_check(delay)
    {:noreply, state}
  end

  defp schedule_status_check(delay) do
    Process.send_after(self(), :update_status, delay)
  end

end
