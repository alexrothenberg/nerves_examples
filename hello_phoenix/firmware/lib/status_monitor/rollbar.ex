defmodule StatusMonitor.Rollbar do
  def update_status do
    IO.inspect ['StatusMonitor.Rollbar.update_status']
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
