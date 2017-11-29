defmodule UiWeb.PageController do
  use UiWeb, :controller

  def index(conn, %{"action" => action}) do
    # Colors.stop()
    apply(Colors, String.to_atom(action), [])

    redirect conn, to: page_path(conn, :index)
  end

  def index(conn, _params) do
    conn
    |> render("index.html")
  end

end
