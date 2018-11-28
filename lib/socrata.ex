defmodule Socrata do
  @moduledoc """
  This library is intended to be as transparent a wrapper as possible for
  the Socrata SODA 2.1+ API.

  ## Installation

  This library is available via Hex. To add it as a dependency to your
  application, add the following to your `mix.exs` file:

      defp deps do
        [
          {:socrata, ">= 0.0.0"}
        ]
      end

  ## Configuration

  There are two optional configuration values that you can supply via your
  application's `config/config.exs` file:

      config :socrata,
        domain: "example.com",
        app_token: "blah blah blah"

  Using the `domain` config sets a default Socrata domain for all of your
  requests. This can be overwritten when calling `Socrata.Client.new/3` if
  you need a one off connection to another Socrata deployment.

  Using the `app_token` add the `X-App-Token` header to all of your requests.
  Having a token greatly increases your rate limit. For more information about
  tokens, see the
  <a href="https://dev.socrata.com/docs/app-tokens.html">Socrata App Tokens docs</a>.

  ## Reading Data from the API

  There are two endpoints that the `Socrata.Client` module will work with:

    - the _views_ endpoint to get data set metadata
    - the _resources_ endpoint to get data set records

  ### Metadata Client Example

      alias Socrata.Client

      Rader.new("6zsd-86xi", "data.cityofchicago.org")
      |> Client.get_view()

      # %HTTPoison.Response{
      #   body: "{\\"name\\": \\"Crimes - 2001 to present\\", ... }",
      #   headers: [ {"X-Socrata-RequestId", "blahblahblah"}, ... ],
      #   request_url: "https://data.cityofchicago.org/views/6zsd-86xi.json",
      #   status_code: 200
      # }

  ### Getting Records as JSON

  By default, calling `Socrata.Client.get_records/4` will use the `.json` API
  syntax and the response body will be encoded JSON.

      alias Socrata.{Client, Query}

      query =
        Query.new()
        |> Query.limit(5)

      Client.new("6zsd-86xi", "data.cityofchicago.org")
      |> Client.get_records(query)

      # %HTTPoison.Response{
      #   body: "[{\\"arrest\\":false,\\"beat\\":\\"0412\\",\\"block\\":\\"016XX E 86TH PL\\", ...}, ... ]",
      #   headers: [ {"X-Socrata-RequestId", "blahblahblah"}, ... ],
      #   request_url: "https://data.cityofchicago.org/resource/6zsd-86xi.json?%24limit=5",
      #   status_code: 200
      # }

  ### Getting Records as CSV

  You can provide a third argument to `Socrata.Client.get_records/4` to specify
  the API response syntax. In this case, we'll set it to `"csv"` and get back
  an encoded CSV document in the response body.

      alias Socrata.{Client, Query}

      query =
        Query.new()
        |> Query.limit(5)

      Client.new("6zsd-86xi", "data.cityofchicago.org")
      |> Client.get_records(query, "csv")

      # %HTTPoison.Response{
      #   body: "\\"arrest\\",\\"beat\\",\\"block\\",...\\n\\"false\\",\\"0412\\",\\"016XX E 86TH PL\\",...\\n",
      #   headers: [ {"X-Socrata-RequestId", "blahblahblah"}, ... ],
      #   request_url: "https://data.cityofchicago.org/resource/6zsd-86xi.csv?%24limit=5",
      #   status_code: 200
      # }

  ### Getting Records as TSV

  You can provide a third argument to `Socrata.Client.get_records/4` to specify
  the API response syntax. In this case, we'll set it to `"tsv"` and get back
  an encoded TSV document in the response body.

      alias Socrata.{Client, Query}

      query =
        Query.new()
        |> Query.limit(5)

      Client.new("6zsd-86xi", "data.cityofchicago.org")
      |> Client.get_records(query, "tsv")

      # %HTTPoison.Response{
      #   body: "\\"arrest\\"\\t\\"beat\\"\\t\\"block\\"\\t...\\n\\"false\\"\\t\\"0412\\"\\t\\"016XX E 86TH PL\\"\\t...\\n",
      #   headers: [ {"X-Socrata-RequestId", "blahblahblah"}, ... ],
      #   request_url: "https://data.cityofchicago.org/resource/6zsd-86xi.tsv?%24limit=5",
      #   status_code: 200
      # }

  ### Getting Records as GeoJSON

  You can provide a third argument to `Socrata.Client.get_records/4` to specify
  the API response syntax. In this case, we'll set it to `"geojson"` and get
  back an encoded GeoJSON document in the response body.

      alias Socrata.{Client, Query}

      query =
        Query.new()
        |> Query.limit(5)

      Client.new("yama-9had", "data.cityofchicago.org")
      |> Client.get_records(query, "geojson")

      # %HTTPoison.Response{
      #   body: "{
      #     "crs": {
      #       "properties": { "name": "urn:ogc:def:crs:OGC:1.3:CRS84" },
      #       "type": "name"
      #     },
      #     "features": [
      #       {
      #         "geometry": {
      #           "coordinates": [-87.725100208587, 41.903236038454],
      #           "type": "Point"
      #         },
      #         "properties": { ... },
      #         "type": "Feature"
      #       },
      #       ...
      #     ],
      #     "type": "FeatureCollection"
      #   }",
      #   headers: [ {"X-Socrata-RequestId", "blahblahblah"}, ... ],
      #   request_url: "https://data.cityofchicago.org/resource/6zsd-86xi.tsv?%24limit=5",
      #   status_code: 200
      # }

  ### Passing HTTPoison Options

  The fourth parameter of `Socrata.Client.get_records/4` is a keyword list of
  options that are directly dumped to the call to `HTTPoison.get!/3` under the
  hood.

  By doing this, the library hands over full control of the request/response
  life cycle to you. By default it sends the request as a standard, synchronous
  blocking call that gets a complete response object.

  Say, for example, you're passing an incredibly time consuming query to the
  API and you know the default 5000 ms timeout will trip your request. You can
  pass the `timeout` key to the options to increase the wait time for the
  response.

      alias Socrata.{Client, Query}

      query =
        Query.new()
        |> Query.select(~w|:id name location|)
        |> Query.where("is_within(location, to_polygon(\" ... \")) and :created_on > ' ... '")
        |> Query.order("name asc")
        |> Query.limit(100)
        |> Query.offset(2_000)

      Client.new("asdf-jkl1", "example.com")
      |> Client.get_records(query, "json", timeout: :60_000)

  You could also convert the standard response to an asynchronous response
  using the `stream_to` key and using a `receive do` block to handle the
  asynchronous response.

      alias Socrata.{Client, Query}

      query =
        Query.new()
        |> Query.select(~w|:id name location|)
        |> Query.where("is_within(location, to_polygon(\" ... \")) and :created_on > ' ... '")
        |> Query.order("name asc")
        |> Query.limit(100)
        |> Query.offset(2_000)

      %HTTPoison.AsyncResponse{id: id} =
        Client.new("asdf-jkl1", "example.com")
        |> Client.get_records(query, "geojson", stream_to: self())
  """
end
