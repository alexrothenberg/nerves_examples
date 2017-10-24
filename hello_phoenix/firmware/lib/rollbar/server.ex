defmodule Rollbar.Server do
  use GenServer
  alias Rollbar.Impl

  def init(store) do
    { :ok, store }
  end

  def handle_call({:get_projects}, _, store) do
    result = Impl.get_projects()
    { :reply, result, store }
  end

  def handle_call({:get_project_read_only_access_token, project_id}, _, store) do
    result = Impl.get_project_read_only_access_token(project_id)
    { :reply, result, store }
  end

  def handle_call({:get_items, project_access_token}, _, store) do
    items = Impl.get_items(project_access_token)
    { :reply, items, store }
  end

end
