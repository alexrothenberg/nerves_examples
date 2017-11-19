defmodule BlinkIt do
  def set_pixel(index, rgbb) do
    GenServer.cast(BlinkIt.Server, {:set_pixel, index, rgbb})
  end

  def show() do
    GenServer.cast(BlinkIt.Server, {:show})
  end

  def get_pixels() do
    GenServer.call(BlinkIt.Server, {:get_pixels})
  end

end
