defmodule Rainbow.Server do
  require Logger

  def start_link do
    Logger.info "Starting Rainbow GenServer #{__MODULE__}"
    GenServer.start_link(__MODULE__, %{}, name: Rainbow.Server)
  end

  def init(%{}) do
    delay = 1000 # 1 second

    Process.send_after(self(), :draw, 20_000)
    {:ok, %{ delay: delay, s: 5 }}
  end

  def handle_info(:draw, %{ delay: delay, s: s }) do
    Enum.each((0..7), &(BlinkIt.set_pixel(&1, rgbb_for(&1, s))))

    BlinkIt.show()

    Process.send_after(self(), :draw, delay)
    {:noreply, %{delay: delay, s: mod(s + 7, 50)} }
  end

  def rgbb_for(index, saturation) do
    # spacing = div(360, 16)
    # offset = index * spacing
    hue = index * div(360, 8) + Enum.random(-5..5)
    value = Enum.random(30..100)
    saturation = 95 #saturation + 40
    hsv = %ColorUtils.HSV{hue: hue, saturation: saturation, value: value}
    %ColorUtils.RGB{blue: blue, green: green, red: red} = ColorUtils.hsv_to_rgb(hsv)
    IO.inspect([index, hsv, %{red: red, green: green, blue: blue, brightness: 7}])
    %{red: red, green: green, blue: blue, brightness: 4}
  end

  def mod(x,y) when x > 0, do: rem(x, y);
  def mod(x,y) when x < 0, do: rem(x, y) + y;
  def mod(0,_y), do: 0
  def mod(0.0,_y), do: 0
end