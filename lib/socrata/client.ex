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
  @type t :: %__MODULE__{fourby: String.t(), domain: String.t(), app_token: String.t()}

  defstruct fourby: nil, domain: nil, app_token: nil

  @doc """
  Creates a new Client struct.
  """
  @spec new(String.t(), String.t(), String.t()) :: Socrata.Client.t()
  def new(fourby, domain \\ nil, app_token \\ nil) do
    domain = Application.get_env(:socrata, :domain, domain)
    token = Application.get_env(:socrata, :app_token, app_token)
    %Socrata.Client{fourby: fourby, domain: domain, app_token: token}
  end

  @doc """
  Gets the view information (metadata) for a data set.

  ## Options

  The `opts` parameter of the function is passed directly to `HTTPoison.get!/3`
  so you can control the request/response life cycle.

  ## Example

      alias Socrata.Client

      Rader.new("6zsd-86xi", "data.cityofchicago.org")
      |> Client.get_view()

      # %HTTPoison.Response{
      #   body: "{\\"name\\": \\"Crimes - 2001 to present\\", ... }",
      #   headers: [ {"X-Socrata-RequestId", "blahblahblah"}, ... ],
      #   request_url: "https://data.cityofchicago.org/views/6zsd-86xi.json",
      #   status_code: 200
      # }
  """
  @spec get_view(Socrata.Client.t(), keyword()) :: HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()
  def get_view(%Socrata.Client{} = r, opts \\ []),
    do: send_request(r, "views", "json", opts)

  @doc """
  Gets the records for a data set.

  ## Options

  The `opts` parameter of the function is passed directly to `HTTPoison.get!/3`
  so you can control the request/response life cycle.

  **Note:** the `params` key of the options is overwritten by the query struct.

  ## Example

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
  """
  @spec get_records(Socrata.Client.t(), Socrata.Query.t(), String.t(), keyword()) :: HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()
  def get_records(%Socrata.Client{} = r, %Socrata.Query{} = query \\ nil, fmt \\ "json", opts \\ [])
    when is_binary(fmt) and fmt in ["json", "csv", "tsv", "geojson"]
  do
    query =
      case query do
        nil   -> Socrata.Query.new()
        query -> query
      end

    opts = Keyword.merge(opts, [params: Enum.into(query.state, [])])

    send_request(r, "resource", fmt, opts)
  end

  @vsn Application.spec(:socrata, :vsn)

  # sends the request to the api
  # params:
  #   - client is the client struct to pluck the 4x4, domain and token
  #   - endpoint is the api endpoint ("view" or "resource")
  #   - format is the response format ("json" or "csv")
  #   - opts is a keyword list of HTTPoison request options
  defp send_request(client, endpoint, format, opts) do
    url = "https://#{client.domain}/#{endpoint}/#{client.fourby}.#{format}"

    headers = ["User-Agent": "socrata-elixir-client v#{@vsn}"]
    headers =
      case client.app_token do
        nil   -> headers
        token -> Keyword.merge(headers, ["X-App-Token": token])
      end

    HTTPoison.get!(url, headers, opts)
  end
end
