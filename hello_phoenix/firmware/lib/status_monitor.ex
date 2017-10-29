defmodule StatusMonitor do
  def get_status do
    GenServer.call(StatusMonitor.Server, {:get_status})
  end

  def get_led_mapping do
    GenServer.call(StatusMonitor.Server, {:get_led_mapping})
  end

  def set_led_mapping(led_mapping) do
    GenServer.call(StatusMonitor.Server, {:set_led_mapping, led_mapping})
  end
end
