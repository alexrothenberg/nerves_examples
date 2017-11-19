defmodule BlinkIt.Impl do
  alias ElixirALE.GPIO
  use Bitwise

  def init() do
    pixels = [
      %{red: 0, green: 0, blue: 0, brightness: 7},
      %{red: 0, green: 0, blue: 0, brightness: 7},
      %{red: 0, green: 0, blue: 0, brightness: 7},
      %{red: 0, green: 0, blue: 0, brightness: 7},
      %{red: 0, green: 0, blue: 0, brightness: 7},
      %{red: 0, green: 0, blue: 0, brightness: 7},
      %{red: 0, green: 0, blue: 0, brightness: 7},
      %{red: 0, green: 0, blue: 0, brightness: 7}
    ]
    {:ok, dat} = GPIO.start_link(23, :output)
    {:ok, clk} = GPIO.start_link(24, :output)
    pins = %{dat: dat, clk: clk}

    %{pins: pins, pixels: pixels}
  end

  def set_pixel(pixels, index, rgbb) do
    # IO.inspect [:blinkt, index, rgbb]
    List.replace_at(pixels, index, rgbb)
  end

  def show(pins, pixels) do
    pulse(pins, 32)
    Enum.each(pixels, fn(pixel)->
      show_pixel(pins, pixel)
    end)
    pulse(pins, 36)
  end

  defp show_pixel(pins, %{red: red, green: green, blue: blue, brightness: brightness}) do
    write_byte(pins, 0b11100000 ||| brightness)
    write_byte(pins, blue)
    write_byte(pins, green)
    write_byte(pins, red)
  end

  defp pulse(%{dat: dat, clk: clk}, ticks) do
    GPIO.write(dat, 0)
    Enum.each(1..ticks, fn(_)->
      GPIO.write(clk, 1)
      GPIO.write(clk, 0)
    end)
  end

  defp write_byte(pins, byte) do
    write_byte(pins, byte, 8)
  end

  defp write_byte(_pins, _byte, 0) do
  end

  defp write_byte(pins, byte, remaining) do
    %{dat: dat, clk: clk} = pins
    GPIO.write(dat, byte &&& 0b10000000)
    GPIO.write(clk, 1)
    GPIO.write(clk, 0)
    # IO.puts(byte &&& 0b10000000)
    write_byte(pins, byte <<< 1, remaining - 1)
  end
end
