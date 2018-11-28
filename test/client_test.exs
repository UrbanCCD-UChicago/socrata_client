defmodule Socrata.ClientTest do
  use ExUnit.Case, async: true

  alias Socrata.{Client, Query}

  @fourby "yama-9had"
  @domain "data.cityofchicago.org"
  @token "KlM3IL5JHZuGUu1EVzA3qSfrf"

  setup_all do
    client = Client.new(@fourby, @domain, @token)
    query = Query.new() |> Query.limit(5)
    {:ok, client: client, query: query}
  end

  describe "get_view/2" do
    test "returns an HTTPoison.Response by default", %{client: client} do
      %HTTPoison.Response{} = Client.get_view(client)
    end

    test "returns a JSON encoded body", %{client: client} do
      %HTTPoison.Response{body: body} = Client.get_view(client)
      _ = Jason.decode!(body)
    end
  end

  describe "get_records/4" do
    test "returns a JSON body by default", %{client: client, query: query} do
      %HTTPoison.Response{body: body} = Client.get_records(client, query)
      _ = Jason.decode!(body)
    end

    test "can be optionally set to return an async response", %{client: client, query: query} do
      %HTTPoison.AsyncResponse{} = Client.get_records(client, query, "json", stream_to: self())
    end
  end
end
