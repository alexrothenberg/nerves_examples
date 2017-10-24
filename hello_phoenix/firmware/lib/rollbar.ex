defmodule Rollbar do
  def init() do
    {:ok, rollbar} = GenServer.start_link(Rollbar.Server, %{})
    rollbar
  end

  def get_projects(rollbar) do
    GenServer.call(rollbar, {:get_projects})
  end

  def get_project_read_only_access_token(rollbar, id) do
    GenServer.call(rollbar, {:get_project_read_only_access_token, id})
  end

  def get_items(rollbar, project_access_token) do
    GenServer.call(rollbar, {:get_items, project_access_token})
  end

end
