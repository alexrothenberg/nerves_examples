defmodule BlinkIt do
  def set_pixel(index, rgbb) do
    GenServer.call(BlinkIt.Server, {:set_pixel, index, rgbb})
  end

  def show() do
    GenServer.call(BlinkIt.Server, {:show})
  end
end
