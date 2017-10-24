defmodule Rollbar do
  def new() do
    {:ok, rollbar} = GenServer.start_link(Rollbar.Server, %{})
    rollbar
  end

  def get_projects(rollbar) do
    GenServer.call(rollbar, {:get_projects})
  end

  def get_project_read_only_access_token(rollbar, id) do
    GenServer.call(rollbar, {:get_project_read_only_access_token, id})
  end

end
