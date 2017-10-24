defmodule Firmware do
  use Application
  alias ElixirALE.GPIO

  @interface Application.get_env(:firmware, :interface, :eth0)

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Phoenix.PubSub.PG2, [Nerves.PubSub, [poolsize: 1]]),
      worker(Task, [fn -> start_network() end], restart: :transient)
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fw.Supervisor]
    Supervisor.start_link(children, opts)
    # IO.inspect(rollbar())

    # {:ok, pin} = GPIO.start_link(24, :output)
    # toggle_pin_forever(pin)
    alex()
  end

  def start_network do
    Nerves.Network.setup to_string(@interface)
  end

  def alex do
    blink_it = BlinkIt.init()
    BlinkIt.set_pixel(blink_it, 1, %{red: 255, green: 0, blue: 0, brightness: 7})
    BlinkIt.set_pixel(blink_it, 2, %{red: 0, green: 255, blue: 0, brightness: 7})
    BlinkIt.set_pixel(blink_it, 3, %{red: 0, green: 0, blue: 255, brightness: 7})
    BlinkIt.set_pixel(blink_it, 4, %{red: 255, green: 127, blue: 0, brightness: 7})
    BlinkIt.set_pixel(blink_it, 5, %{red: 255, green: 0, blue: 127, brightness: 7})
    BlinkIt.set_pixel(blink_it, 6, %{red: 0, green: 255, blue: 127, brightness: 7})
    BlinkIt.set_pixel(blink_it, 7, %{red: 0, green: 127, blue: 0, brightness: 1})
    BlinkIt.set_pixel(blink_it, 8, %{red: 0, green: 127, blue: 0, brightness: 31})
    BlinkIt.show(blink_it)
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

  def rollbar do
    rollbar = Rollbar.new
    projects = Rollbar.get_projects(rollbar)
    access_tokens = Enum.map(projects, fn(project)->
      id = project["id"]
      access_token = Rollbar.get_project_read_only_access_token(rollbar, id)
      %{name: project["name"], id: id, access_token: access_token}
    end)
    # {:ok, response} = HTTPoison.get("https://api.rollbar.com/api/1/projects\?access_token\=0c063875c96f4226844835f37bf918ff")
    # {:ok, result} = Poison.decode(response.body)
    # HTTPoison.get("https://api.rollbar.com/api/1/items/\?access_token\=cb878b4135974295ac30f07b3b630dcb")
  end

end
