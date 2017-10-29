defmodule StatusMonitor.Rollbar do
  def fetch_status() do
    rollbar_access_tokens()
      |> Enum.map(&last_rollbar_error/1)
  end

  def draw(led_mapping, status) do
    Enum.map(0..7, fn(led_index)->
      rgbb = led_index
        |> Integer.to_string
        |> (&(led_mapping[&1])).()
        |> Enum.map(fn(name)->
          Enum.find(status, &( &1.name == name))
        end)
        |> Enum.sort
        |> List.last
        |> (&(&1.seconds_ago)).()
        |> to_rgbb
      BlinkIt.set_pixel(led_index, rgbb)
    end)
    BlinkIt.show()
  end

  def rollbar_access_tokens() do
    Rollbar.get_projects()
      |> Enum.map(fn(project)->
        access_token = Rollbar.get_project_read_only_access_token(project["id"])
        [project["name"], access_token]
      end)
      |> Enum.map(fn [a,b]-> {a,b} end)
      |> Map.new
  end


  def one_minute_in_seconds, do: 60
  def one_hour_in_seconds, do: one_minute_in_seconds() * 60
  def one_day_in_seconds, do: one_hour_in_seconds() * 24

  def last_rollbar_error({project_name, project_access_token}) do
    latest_item = Rollbar.get_items(project_access_token)
      |> List.first
    with %{ "last_occurrence_timestamp" => last_occurrence_timestamp } <- latest_item
    do
      seconds_ago = DateTime.utc_now
        |> DateTime.diff(DateTime.from_unix!(last_occurrence_timestamp))
      %{ name: project_name, seconds_ago: seconds_ago }
    else
      nil -> %{ name: project_name }
    end
  end

  def to_rgbb(seconds) do
    days_ago = div(seconds, one_day_in_seconds())
    if (days_ago > 7) do
      # green
      %{
        red: 0,
        blue: 0,
        green: 18,
        brightness: 3
      }
    else
      if (days_ago < 1) do
        # red
        %{
          red: 255,
          green: 0,
          blue: 0,
          brightness: 31
        }
      else
        # pink
        %{
          red: 127,
          green: 18,
          blue: 18,
          brightness: 7
        }
      end
    end
  end
end
