defmodule Rollbar.Impl do
  def new() do
    %{}
  end

  def get_projects(access_token) do
    {:ok, response} = HTTPoison.get(
      "https://api.rollbar.com/api/1/projects?access_token=#{access_token}",
      [],
      hackney: [:insecure]
      )
    {:ok, body} = Poison.decode(response.body)
    body["result"]
  end

  def get_project_read_only_access_token(access_token, id) do
    {:ok, response} = HTTPoison.get(
      "https://api.rollbar.com/api/1/project/#{id}/access_tokens?access_token=#{access_token}",
      [],
      hackney: [:insecure]
      )
    {:ok, body} = Poison.decode(response.body)
    access_tokens = body["result"]
    access_token = Enum.find(access_tokens, fn(x)-> x["name"] == "read" end)
    access_token["access_token"]
  end

  def get_items(project_access_token) do
    {:ok, response} = HTTPoison.get(
      "https://api.rollbar.com/api/1/items?access_token=#{project_access_token}&status=active",
      [],
      hackney: [:insecure]
      )
    {:ok, %{ "result" => %{ "items" => items }}} = Poison.decode(response.body)
    items
  end

end
