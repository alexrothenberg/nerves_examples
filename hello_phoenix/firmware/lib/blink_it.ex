defmodule BlinkIt do
  def init() do
    {:ok, blink_it} = GenServer.start_link(BlinkIt.Server, %{})
    blink_it
  end

  def set_pixel(blink_it, index, rgbb) do
    GenServer.call(blink_it, {:set_pixel, index, rgbb})
  end

  def show(blink_it) do
    GenServer.call(blink_it, {:show})
  end
end
