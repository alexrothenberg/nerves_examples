defmodule BlinkIt.Server do
  use GenServer
  alias BlinkIt.Impl

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: BlinkIt.Server)
  end

  def init(_args) do
    {:ok, Impl.init() }
  end

  def handle_call({:set_pixel, pixel_index, rgbb}, _, %{pins: pins, pixels: pixels}) do
    new_pixels = Impl.set_pixel(pixels, pixel_index, rgbb)
    {:reply, {}, %{pins: pins, pixels: new_pixels}}
  end

  def handle_call({:show}, _, %{pins: pins, pixels: pixels}) do
    Impl.show(pins, pixels)
    {:reply, {}, %{pins: pins, pixels: pixels}}
  end
end
