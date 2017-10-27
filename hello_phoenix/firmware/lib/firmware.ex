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
    # alex()
  end

  def start_network do
    Nerves.Network.setup to_string(@interface)
  end

  def alex do
    blink_it = BlinkIt.init()
    BlinkIt.set_pixel(blink_it, 0, %{red: 0, green: 0, blue: 255, brightness: 1})
    BlinkIt.set_pixel(blink_it, 1, %{red: 0, green: 0, blue: 255, brightness: 1})
    BlinkIt.set_pixel(blink_it, 2, %{red: 0, green: 0, blue: 50, brightness: 1})
    BlinkIt.set_pixel(blink_it, 3, %{red: 50, green: 27, blue: 0, brightness: 1})
    BlinkIt.set_pixel(blink_it, 4, %{red: 185, green: 48, blue: 5, brightness: 1})
    BlinkIt.set_pixel(blink_it, 5, %{red: 165, green: 42, blue: 42, brightness: 1})
    BlinkIt.set_pixel(blink_it, 6, %{red: 165, green: 42, blue: 42, brightness: 1})
    BlinkIt.set_pixel(blink_it, 7, %{red: 245, green: 222, blue: 147, brightness: 1})
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

  def rollbar_access_tokens(rollbar) do
    projects = Rollbar.get_projects(rollbar)
    projects
    |> Enum.map(fn(project)->
      id = project["id"]
      access_token = Rollbar.get_project_read_only_access_token(rollbar, id)
      # %{name: project["name"], id: id, access_token: access_token}
      [project["name"], access_token]
    end)
    |> Enum.map(fn [a,b]-> {a,b} end)
    |> Map.new
  end

  def rollbar do
    System.cmd("/usr/sbin/ntpd", ["-n", "-q", "-p", "0.pool.ntp.org", "-p", "1.pool.ntp.org", "-p", "2.pool.ntp.org", "-p", "3.pool.ntp.org"])

    rollbar = Rollbar.init()
    access_tokens = rollbar_access_tokens(rollbar)

    blink_it = BlinkIt.init()
    show_rollbar_pixel(rollbar, blink_it, 0, [access_tokens["api_gateway"], access_tokens["Apothecary"]])
    show_rollbar_pixel(rollbar, blink_it, 1, [access_tokens["BCI_Services"], access_tokens["Bouncah"]])
    show_rollbar_pixel(rollbar, blink_it, 2, [access_tokens["Delorean"], access_tokens["feature_toggles"], ])
    show_rollbar_pixel(rollbar, blink_it, 3, [access_tokens["norman"], access_tokens["patient_log"]])
    show_rollbar_pixel(rollbar, blink_it, 4, [access_tokens["Patients"], access_tokens["postmaster"]])
    show_rollbar_pixel(rollbar, blink_it, 5, [access_tokens["referrals"], access_tokens["salk"]])
    show_rollbar_pixel(rollbar, blink_it, 6, [access_tokens["snowflake"], access_tokens["staff"]])
    show_rollbar_pixel(rollbar, blink_it, 7, [access_tokens["takotsubo"]])
    BlinkIt.show(blink_it)
  end

  def one_minute_in_seconds, do: 60
  def one_hour_in_seconds, do: one_minute_in_seconds() * 60
  def one_day_in_seconds, do: one_hour_in_seconds() * 24

  def show_rollbar_pixel(rollbar, blink_it, pixel_index, project_access_tokens) do
    rgbb = Enum.map(project_access_tokens, fn(project_access_token)->
      last_rollbar_error(rollbar, project_access_token)
    end)
    |> Enum.sort
    |> List.last
    |> IO.inspect
    |> to_rgbb
    BlinkIt.set_pixel(blink_it, pixel_index, rgbb)
    # BlinkIt.show(blink_it)
  end

  def last_rollbar_error(rollbar, project_access_token) do
    %{ "last_occurrence_timestamp" => last_occurrence_timestamp } =
      Rollbar.get_items(rollbar, project_access_token)
      |> List.first
    DateTime.utc_now
      |> DateTime.diff(DateTime.from_unix!(last_occurrence_timestamp))
  end

  def to_rgbb(seconds) do
    days_ago = div(seconds, one_day_in_seconds())
    if (days_ago > 7) do
      %{
        red: 18,
        blue: 18,
        green: 18,
        brightness: 3
      }
    else
      %{
        red: red_for(seconds),
        blue: blue_for(seconds),
        green: green_for(seconds),
        brightness: brightness_for(seconds)
      }
    end
  end

  def red_for(seconds) do
    if (seconds < one_day_in_seconds()) do
      255
    else
      days_ago = div(seconds, one_day_in_seconds())
      div(127, days_ago)
    end
  end

  def blue_for(seconds) do
    days_ago = div(seconds, one_day_in_seconds())
    if (days_ago > 7) do
      18
    else
      18 * days_ago
    end
  end

  def green_for(seconds) do
    days_ago = div(seconds, one_day_in_seconds())
    if (days_ago > 7) do
      18
    else
      18 * days_ago
    end
  end

  def brightness_for(seconds) do
    days_ago = div(seconds, one_day_in_seconds())
    if (days_ago < 1) do
      31
    else
      7
    end
  end

end


# System.cmd("/usr/sbin/ntpd", ["-n", "-q", "-p", "0.pool.ntp.org", "-p", "1.pool.ntp.org", "-p", "2.pool.ntp.org", "-p", "3.pool.ntp.org"])
