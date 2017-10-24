defmodule Rollbar.Impl do
  def new() do
    %{}
  end

  def get_projects() do
    {:ok, response} = HTTPoison.get(
      "https://api.rollbar.com/api/1/projects\?access_token\=0c063875c96f4226844835f37bf918ff",
      [],
      hackney: [:insecure]
      )
    {:ok, body} = Poison.decode(response.body)
    body["result"]
  end

  def get_project_read_only_access_token(id) do
    {:ok, response} = HTTPoison.get(
      "https://api.rollbar.com/api/1/project/#{id}/access_tokens\?access_token\=0c063875c96f4226844835f37bf918ff",
      [],
      hackney: [:insecure]
      )
    {:ok, body} = Poison.decode(response.body)
    access_tokens = body["result"]
    access_token = Enum.find(access_tokens, fn(x)-> x["name"] == "read" end)
    access_token["access_token"]
  end
end
