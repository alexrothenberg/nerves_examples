defmodule BlinkIt.Server do
  use GenServer
  alias BlinkIt.Impl

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: BlinkIt.Server)
  end

  def init(_args) do
    {:ok, Impl.init() }
  end

  def handle_cast({:set_pixel, pixel_index, rgbb}, %{pins: pins, pixels: pixels}) do
    new_pixels = Impl.set_pixel(pixels, pixel_index, rgbb)
    {:noreply, %{pins: pins, pixels: new_pixels}}
  end

  def handle_call({:get_pixels}, _, %{pixels: pixels}=state) do
    {:reply, pixels, state}
  end

  def handle_cast({:show}, %{pins: pins, pixels: pixels}=state) do
    Impl.show(pins, pixels)
    {:noreply, state}
  end
end
