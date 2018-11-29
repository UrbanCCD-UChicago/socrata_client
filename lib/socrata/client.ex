defmodule Socrata.Client do
  @moduledoc """
  The Client is the main interface of the library. Using a Client, you can
  get the records and metadata for a data set.

  The Client accepts optional paramaters `domain` and `app_token`. These values
  can either be configured when you call `new/3` or in your application's
  `config/config.exs` file:

      config :socrata,
        domain: "example.com",
        app_token: "blah blah blah"

  For more information about tokens and their use, see the
  <a href="https://dev.socrata.com/docs/app-tokens.html">Socrata App Tokens docs</a>.
  """

  @typedoc ""
  @type t :: %__MODULE__{domain: String.t(), app_token: String.t()}

  defstruct domain: nil, app_token: nil

  @doc """
  Creates a new Client struct.

  ## Examples

      iex> # either no token or relying on app config
      iex> alias Socrata.Client
      iex> Client.new("data.cityofchicago.org")
      %Socrata.Client{domain: "data.cityofchicago.org", app_token: nil}

      iex> # explicitly setting up with a token
      iex> alias Socrata.Client
      iex> Client.new("data.cityofchicago.org", "blah blah blah")
      %Socrata.Client{domain: "data.cityofchicago.org", app_token: "blah blah blah"}
  """
  @spec new(String.t(), String.t()) :: Socrata.Client.t()
  def new(domain \\ nil, app_token \\ nil) do
    domain = Application.get_env(:socrata, :domain, domain)
    token = Application.get_env(:socrata, :app_token, app_token)

    %Socrata.Client{domain: domain, app_token: token}
  end

  @doc """
  Gets the view information (metadata) for a data set.

  ## Options

  The `opts` parameter of the function is passed directly to `HTTPoison.get!/3`
  so you can control the request/response life cycle.

  ## Example

      iex> alias Socrata.Client
      iex> %HTTPoison.Response{body: body} = Client.new("data.cityofchicago.org") |> Client.get_view("yama-9had")
      iex> details = Jason.decode!(body)
      iex> Map.keys(details)
      ["oid", "publicationAppendEnabled", "category", "numberOfComments", "createdAt", "attribution", "hideFromDataJson", "query", "id", "tableAuthor", "rights", "tableId", "attributionLink", "owner", "viewCount", "grants", "downloadCount", "flags", "publicationGroup", "name", "averageRating", "publicationDate", "hideFromCatalog", "provenance", "totalTimesRated", "description", "metadata", "viewLastModified", "rowsUpdatedAt", "rowsUpdatedBy", "viewType", "newBackend", "publicationStage", "tags", "columns"]
  """
  @spec get_view(Socrata.Client.t(), String.t(), keyword()) :: HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()
  def get_view(%Socrata.Client{} = r, fourby, opts \\ []),
    do: send_request(r, "views", fourby, "json", opts)

  @doc """
  Gets the records for a data set.

  ## Options

  The `opts` parameter of the function is passed directly to `HTTPoison.get!/3`
  so you can control the request/response life cycle.

  **Note:** the `params` key of the options is overwritten by the query struct.

  ## Examples

        iex> # get regular json response
        iex> alias Socrata.{Client, Query}
        iex> client = Client.new("data.cityofchicago.org")
        iex> query = Query.new("yama-9had") |> Query.limit(2)
        iex> %HTTPoison.Response{body: body} = Client.get_records(client, query)
        iex> records = Jason.decode!(body)
        iex> length(records)
        2

        iex> # get csv response
        iex> alias Socrata.{Client, Query}
        iex> client = Client.new("data.cityofchicago.org")
        iex> query = Query.new("yama-9had") |> Query.limit(2)
        iex> %HTTPoison.Response{body: body} = Client.get_records(client, query, "csv")
        iex> {:ok, stream} = StringIO.open(body)
        iex> records = IO.binstream(stream, :line) |> CSV.decode!(headers: true) |> Enum.map(& &1)
        iex> length(records)
        2

        iex> # get tsv response
        iex> alias Socrata.{Client, Query}
        iex> client = Client.new("data.cityofchicago.org")
        iex> query = Query.new("yama-9had") |> Query.limit(2)
        iex> %HTTPoison.Response{body: body} = Client.get_records(client, query, "tsv")
        iex> {:ok, stream} = StringIO.open(body)
        iex> records = IO.binstream(stream, :line) |> CSV.decode!(separator: ?\\t, headers: true) |> Enum.map(& &1)
        iex> length(records)
        2

        iex> # get geojson response
        iex> alias Socrata.{Client, Query}
        iex> client = Client.new("data.cityofchicago.org")
        iex> query = Query.new("yama-9had") |> Query.limit(2)
        iex> %HTTPoison.Response{body: body} = Client.get_records(client, query, "geojson")
        iex> %{"crs" => _, "type" => "FeatureCollection", "features" => records} = Jason.decode!(body)
        iex> length(records)
        2

        # get an asynchronous response
        iex> alias Socrata.{Client, Query}
        iex> client = Client.new("data.cityofchicago.org")
        iex> query = Query.new("yama-9had") |> Query.limit(2)
        iex> %HTTPoison.AsyncResponse{id: id} = Client.get_records(client, query, "json", stream_to: self())
        iex> is_reference(id)
        true
  """
  @spec get_records(Socrata.Client.t(), Socrata.Query.t(), String.t(), keyword()) :: HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()
  def get_records(%Socrata.Client{} = r, %Socrata.Query{} = query \\ nil, fmt \\ "json", opts \\ [])
    when is_binary(fmt) and fmt in ["json", "csv", "tsv", "geojson"]
  do
    opts = Keyword.merge(opts, [params: Enum.into(query.state, [])])
    send_request(r, "resource", query.fourby, fmt, opts)
  end

  @vsn Application.spec(:socrata, :vsn)

  # sends the request to the api
  # params:
  #   - client is the client struct to pluck the 4x4, domain and token
  #   - endpoint is the api endpoint ("view" or "resource")
  #   - fourby is the data set indentifier from the query
  #   - format is the response format ("json" or "csv")
  #   - opts is a keyword list of HTTPoison request options
  defp send_request(client, endpoint, fourby, format, opts) do
    url = "https://#{client.domain}/#{endpoint}/#{fourby}.#{format}"

    headers = ["User-Agent": "socrata-elixir-client v#{@vsn}"]
    headers =
      case client.app_token do
        nil   -> headers
        token -> Keyword.merge(headers, ["X-App-Token": token])
      end

    HTTPoison.get!(url, headers, opts)
  end
end
