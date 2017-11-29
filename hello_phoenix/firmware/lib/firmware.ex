defmodule Firmware do
  use Application
  alias ElixirALE.GPIO
  require Logger

  @interface Application.get_env(:firmware, :interface, :eth0)

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Phoenix.PubSub.PG2, [Nerves.PubSub, [poolsize: 1]]),
      worker(Task, [fn -> start_network() end], restart: :transient),
      worker(BlinkIt.Server, []),
      worker(Colors.Server, [])
    ]


    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fw.Supervisor]
    Supervisor.start_link(children, opts)

    # {:ok, pin} = GPIO.start_link(24, :output)
    # toggle_pin_forever(pin)
    # alex()
  end

  def start_network do
    Logger.info "Setting up Network in Firmware.start_network()"
    Nerves.Network.setup to_string(@interface)

    Logger.info "Done setting up Network in Firmware.start_network()"
  end

  def leo do
    BlinkIt.set_pixel(0, %{red: 134, green: 234, blue: 34,   brightness: 3})
    BlinkIt.set_pixel(1, %{red: 225,   green: 200,   blue: 50, brightness: 1})
    BlinkIt.set_pixel(2, %{red: 50,   green: 200,   blue: 75,  brightness: 1})
    BlinkIt.set_pixel(3, %{red: 51, green: 255,  blue: 204,   brightness: 1})
    BlinkIt.set_pixel(4, %{red: 0, green: 136,  blue: 5,   brightness: 1})
    BlinkIt.set_pixel(5, %{red: 255, green: 0,  blue: 0,  brightness: 1})
    BlinkIt.set_pixel(6, %{red: 0, green: 0,  blue: 255,  brightness: 1})
    BlinkIt.set_pixel(7, %{red: 153, green: 254, blue: 1, brightness: 1})
    BlinkIt.show()
  end

  def toggle_pin_forever(output_pid) do
    IO.puts "Turning pin ON"
    GPIO.write(output_pid, 1)
    Process.sleep(500)

    IO.puts "Turning pin OFF"
    GPIO.write(output_pid, 0)
    Process.sleep(500)

    # toggle_pin_forever(output_pid)
  end


end


# System.cmd("/usr/sbin/ntpd", ["-n", "-q", "-p", "0.pool.ntp.org", "-p", "1.pool.ntp.org", "-p", "2.pool.ntp.org", "-p", "3.pool.ntp.org"])
