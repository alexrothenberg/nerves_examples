defmodule Rollbar do
  def get_projects() do
    GenServer.call(Rollbar.Server, {:get_projects})
  end

  def get_project_read_only_access_token(id) do
    GenServer.call(Rollbar.Server, {:get_project_read_only_access_token, id})
  end

  def get_items(project_access_token) do
    GenServer.call(Rollbar.Server, {:get_items, project_access_token})
  end

end
