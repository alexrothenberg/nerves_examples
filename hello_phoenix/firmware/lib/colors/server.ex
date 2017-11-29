defmodule Colors.Server do
  alias ColorUtils.HSV
  require Logger

  def start_link do
    Logger.info "Starting Colors GenServer #{__MODULE__}"
    GenServer.start_link(__MODULE__, %{}, name: Colors.Server)
  end

  def init(%{}) do
    delay = 500 # 0.5 second

    {:ok, %{ delay: delay, iteration: 0 }}
  end

  def handle_cast(:rainbow, state) do
    handle_info(:rainbow, state)
  end

  def handle_cast(:xmas, state) do
    handle_info(:xmas, state)
  end

  def handle_info(:rainbow, %{ delay: delay, iteration: i }) do
    Enum.each((0..7), &(BlinkIt.set_pixel(&1, rgbb_for(&1, i))))

    BlinkIt.show()

    Process.send_after(self(), :rainbow, delay)
    {:noreply, %{delay: delay, iteration: i + 1} }
  end

  def handle_info(:xmas, %{ delay: delay, iteration: iteration }) do
    # IO.inspect({:xmas, iteration})
    red_rgbb = %{red: 255, green: 0, blue: 0, brightness: 7}
    green_rgbb = %{red: 0, green: 255, blue: 0, brightness: 7}

    colors = [
      red_rgbb,
      red_rgbb,
      red_rgbb,
      green_rgbb,
      green_rgbb,
      green_rgbb
    ]
    Enum.each((0..7), fn(x)->
      index = mod((x+iteration), 6)
      BlinkIt.set_pixel(x, Enum.at(colors, index))
    end)

    BlinkIt.show()

    Process.send_after(self(), :xmas, delay)
    {:noreply, %{delay: delay, iteration: iteration + 1} }
  end

  # def handle_info(:draw_gradient, %{ delay: delay, v: v, r: r, g: g, b: b }) do
  #   num_pixels = 8
  #   hue_start = 0
  #   hue_range = 120
  #   max_brightness = 0.2

  #   v = v * num_pixels
  #   Enum.each((0..7), fn(i)->
  #   #   &(BlinkIt.set_pixel(&1, rgbb_for(&1, i))))
  #   # for x in range(blinkt.num_pixels):
  #     hue = ((hue_start + ((i / num_pixels)) * hue_range)) % 360) |> mod(360)
  #     brightness = 7
  #     rgbb = rgbb_for(%HSV{hue: hue, saturation: 100, value: 100}, brightness)
  #     BlinkIt.set_pixel(i, rgbb)

  #     Process.send_after(self(), :draw_gradient, delay)
  #       v -= 1

  #   blinkt.show()


  def rgbb_for(%HSV{hue: hue, saturation: saturation, value: value}=hsv, brightness) do
    # IO.inspect hsv
    %ColorUtils.RGB{blue: blue, green: green, red: red} = ColorUtils.hsv_to_rgb(hsv)
    # IO.inspect([%{red: red, green: green, blue: blue, brightness: 7}])
    %{red: red, green: green, blue: blue, brightness: brightness}
  end

  def rgbb_for(index, i) do
    hue = index * div(360, 8) + Enum.random(0..10) |> mod(360)
    value = Enum.random(30..100)
    saturation = mod(i * 7, 50) + 50
    rgbb_for(%HSV{hue: hue, saturation: saturation, value: value}, 1)
  end

  def mod(x,y) when x > 0, do: rem(x, y);
  def mod(x,y) when x < 0, do: rem(x, y) + y;
  def mod(0,_y), do: 0
  def mod(0.0,_y), do: 0
end