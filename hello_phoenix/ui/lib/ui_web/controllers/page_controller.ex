defmodule UiWeb.PageController do
  use UiWeb, :controller

  def index(conn, %{"action" => action}) do
    # Colors.stop()
    apply(Colors, String.to_atom(action), [])

    redirect conn, to: page_path(conn, :index)
  end

  def index(conn, _params) do
    conn
    |> assign(:last_update, StatusMonitor.get_last_update())
    |> assign(:led_mapping, StatusMonitor.get_led_mapping())
    |> assign(:status, StatusMonitor.get_status())
    |> render("index.html")
  end
end
