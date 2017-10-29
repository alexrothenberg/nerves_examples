defmodule Rollbar.Server do
  use GenServer
  alias Rollbar.Impl
  require Logger

  def start_link do
    Logger.info "Starting Rollbar GenServer #{__MODULE__}"
    GenServer.start_link(__MODULE__, %{}, name: Rollbar.Server)
  end

  def init(store) do
    Logger.info "Initing Rollbar GenServer"
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
