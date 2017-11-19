defmodule UiWeb.PageController do
  use UiWeb, :controller

  def index(conn, _params) do
    conn
    |> render("index.html")
  end
end
