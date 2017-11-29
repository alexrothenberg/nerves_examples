defmodule Colors do
  def stop() do
    GenServer.stop(Colors.Server)
  end

  def xmas() do
    GenServer.cast(Colors.Server, :xmas)
  end

  def rainbow() do
    GenServer.cast(Colors.Server, :rainbow)
  end

end
