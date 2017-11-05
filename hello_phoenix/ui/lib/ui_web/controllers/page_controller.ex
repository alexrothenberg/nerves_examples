defmodule UiWeb.PageController do
  use UiWeb, :controller

  def index(conn, _params) do
    led_mapping = StatusMonitor.get_led_mapping()
    status = StatusMonitor.get_status()
    render conn, "index.html", led_mapping: led_mapping, status: status
  end
end
