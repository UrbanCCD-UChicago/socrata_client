defmodule Socrata.Client do
  @moduledoc """
  The Client is the main interface of the library. Using a Client, you can
  get the records and metadata for a data set.

  The Client accepts optional paramaters `default_format` and `app_token`.
  These values can either be configured when you call `new/3` or in your
  application's `config/config.exs` file:

      config :socrata,
        default_format: "json",
        app_token: "blah blah blah"

  For more information about tokens and their use, see the
  <a href="https://dev.socrata.com/docs/app-tokens.html">Socrata App Tokens docs</a>.
  """

  alias HTTPoison.{AsyncResponse, Response}
  alias Socrata.Query

  @token      Application.get_env(:socrata, :app_token)
  @fmt        Application.get_env(:socrata, :default_format, "json")
  @vsn        Application.spec(:socrata, :vsn)
  @user_agent {:"User-Agent", "Elixir Socrata v#{@vsn} -- UrbanCCD-UChicago/socrata_client"}

  @type response  :: {:ok, Response.t() | AsyncResponse.t()}
  @type response! :: Response.t() | AsyncResponse.t()

  @doc """
  Gets the view information (metadata) for a data set.

  ## Options

  There is one key that the function looks for in the `opts` argument:

  - `app_token` is used to configure the `X-App-Token` header if the value
    was either not set in the application config or override it for this call.

  The remainder of `opts` is passed directly to `HTTPoison.get!/3` so you can
  control the request/response life cycle.

  ## Example

      iex> alias Socrata.{Client, Query}
      iex> q = Query.new(fourby: "yama-9had", domain: "data.cityofchicago.org")
      iex> {:ok, %HTTPoison.Response{body: body}} = Client.get_view(q)
      iex> details = Jason.decode!(body)
      iex> Map.keys(details)
      ["oid", "publicationAppendEnabled", "category", "numberOfComments", "createdAt", "attribution", "hideFromDataJson", "query", "id", "tableAuthor", "rights", "tableId", "attributionLink", "owner", "viewCount", "grants", "downloadCount", "flags", "publicationGroup", "name", "averageRating", "publicationDate", "hideFromCatalog", "provenance", "totalTimesRated", "description", "metadata", "viewLastModified", "rowsUpdatedAt", "rowsUpdatedBy", "viewType", "newBackend", "publicationStage", "tags", "columns"]
  """
  @spec get_view(Query.t(), keyword()) :: response()
  def get_view(query, opts \\ []) do
    # format the url using the query's domain and 4x
    url = "https://#{query.domain}/views/#{query.fourby}.json"

    # get the headers and httpoison options
    {headers, opts} = pop_headers(opts)

    # send the request
    HTTPoison.get(url, headers, opts)
  end

  @doc """
  Gets the response object from `Socrata.Client.get_view/2` or raises an error.
  """
  @spec get_view!(Query.t(), keyword()) :: response!()
  def get_view!(query, opts \\ []) do
    {:ok, resp} = get_view(query, opts)
    resp
  end

  @doc """
  Gets the records for a data set.

  ## Options

  There are two keys that the function looks for in the `opts` argument:

  - `app_token` is used to configure the `X-App-Token` header if the value
    was either not set in the application config or override it for this call.
  - `format` is used to specify the response content type -- this defaults to
    `"json"`.

  The remainder of `opts` is passed directly to `HTTPoison.get!/3` so you can
  control the request/response life cycle.

  ## Examples

        iex> # get regular json response
        iex> alias Socrata.{Client, Query}
        iex> query = Query.new("yama-9had", "data.cityofchicago.org") |> Query.limit(2)
        iex> {:ok, %HTTPoison.Response{body: body}} = Client.get_records(query)
        iex> records = Jason.decode!(body)
        iex> length(records)
        2

        iex> # get csv response
        iex> alias Socrata.{Client, Query}
        iex> query = Query.new("yama-9had", "data.cityofchicago.org") |> Query.limit(2)
        iex> {:ok, %HTTPoison.Response{body: body}} = Client.get_records(query, format: "csv")
        iex> {:ok, stream} = StringIO.open(body)
        iex> records = IO.binstream(stream, :line) |> CSV.decode!(headers: true) |> Enum.map(& &1)
        iex> length(records)
        2

        iex> # get tsv response
        iex> alias Socrata.{Client, Query}
        iex> query = Query.new("yama-9had", "data.cityofchicago.org") |> Query.limit(2)
        iex> {:ok, %HTTPoison.Response{body: body}} = Client.get_records(query, format: "tsv")
        iex> {:ok, stream} = StringIO.open(body)
        iex> records = IO.binstream(stream, :line) |> CSV.decode!(separator: ?\\t, headers: true) |> Enum.map(& &1)
        iex> length(records)
        2

        iex> # get geojson response
        iex> alias Socrata.{Client, Query}
        iex> query = Query.new("yama-9had", "data.cityofchicago.org") |> Query.limit(2)
        iex> {:ok, %HTTPoison.Response{body: body}} = Client.get_records(query, format: "geojson")
        iex> %{"crs" => _, "type" => "FeatureCollection", "features" => records} = Jason.decode!(body)
        iex> length(records)
        2

        # get an asynchronous response
        iex> alias Socrata.{Client, Query}
        iex> query = Query.new("yama-9had", "data.cityofchicago.org") |> Query.limit(2)
        iex> {:ok, %HTTPoison.AsyncResponse{id: id}} = Client.get_records(query, stream_to: self())
        iex> is_reference(id)
        true
  """
  @spec get_records(Query.t(), keyword()) :: response()
  def get_records(query, opts \\ []) do
    # pop the response body format from the opts; defaults to app
    # config default; defaults to json. format the url.
    {fmt, opts} = Keyword.pop(opts, :format, @fmt)
    url = "https://#{query.domain}/resource/#{query.fourby}.#{fmt}"

    # get the headers and httpoison options
    {headers, opts} = pop_headers(opts)

    # add the query as the httpoison `params` option
    opts = Keyword.merge(opts, [params: Enum.into(query.state, [])])

    # send the request
    HTTPoison.get(url, headers, opts)
  end

  @doc """
  Gets the response object from `Socrata.Client.get_records/2` or raises an error.
  """
  @spec get_records!(Query.t(), keyword()) :: response!()
  def get_records!(query, opts \\ []) do
    {:ok, resp} = get_records(query, opts)
    resp
  end

  # pops a possible `:headers` key from the opts and augments it
  # with default values. this guarantees a "User-Agent" header is
  # sent and checks for `:app_token` in either the opts or the
  # application config and adds it as "X-App-Token" if not null.
  defp pop_headers(opts) do
    # pop :app_token from the opts, default to app config, default to nil
    {token, opts} = Keyword.pop(opts, :app_token, @token)

    # set default headers
    default_headers =
      case token do
        nil -> [@user_agent]
        _   -> [@user_agent, {:"X-App-Token", token}]
      end

    # pop :headers from the opts, merge with defaults
    {user_headers, opts} = Keyword.pop(opts, :headers, [])
    headers =
      user_headers
      |> Keyword.merge(default_headers)

    # return the headers and the cleaned httpoison options
    {headers, opts}
  end

end
