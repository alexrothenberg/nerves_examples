defmodule StatusMonitor.Rollbar do
  def fetch_status() do
    rollbar_access_tokens()
    |> Enum.map(&last_rollbar_error/1)
  end

  def draw(led_mapping, status) do
    rgbbs = Enum.map(led_mapping, fn(project_names)->
      project_names
      |> Enum.map(fn(name)->
        Enum.find(status, &(&1.name == name))
      end)
      |> Enum.sort(fn(project, other_project)->
        cond do
          !Map.has_key?(project, :seconds_ago) ->
            true
          !Map.has_key?(other_project, :seconds_ago) ->
            false
          true ->
            project.seconds_ago >= other_project.seconds_ago
        end
      end)
      |> List.last()
      |> to_rgbb()
    end)

    draw_pixels(0, rgbbs)
    BlinkIt.show()
  end

  def draw_pixels(_, []), do: true
  def draw_pixels(led_index, [rgbb | rest]) do
    BlinkIt.set_pixel(led_index, rgbb)
    draw_pixels(led_index + 1, rest)
  end

  def rollbar_access_tokens() do
    Rollbar.get_projects()
      |> Enum.map(fn(project)->
        access_token = Rollbar.get_project_read_only_access_token(project["id"])
        [project["name"], access_token]
      end)
      |> Enum.filter(&(&1 != [nil, nil]))
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

  def to_rgbb(%{ seconds_ago: seconds_ago}) do
    hours_ago = div(seconds_ago, one_hour_in_seconds())
    days_ago = div(seconds_ago, one_day_in_seconds())
    cond do
      hours_ago < 1 ->
        # bright red
        %{
          red: 255,
          green: 0,
          blue: 0,
          brightness: 31
        }
      hours_ago < 6 ->
        # red
        %{
          red: 50,
          green: 0,
          blue: 0,
          brightness: 7
        }
      days_ago < 3 ->
        # orange
        %{
          red: 90,
          green: 20,
          blue: 0,
          brightness: 3
        }
      days_ago < 7 ->
        # yellow
        %{
          red: 98,
          green: 18,
          blue: 0,
          brightness: 3
        }
      true ->
        # green
        %{
          red: 0,
          blue: 0,
          green: 18,
          brightness: 3
        }
    end
  end

  def to_rgbb(_project) do
    # bright_green
    %{
      red: 0,
      blue: 0,
      green: 77,
      brightness: 7
    }
  end

end
