defmodule Socrata.Query do
  @moduledoc """
  Queries are the building blocks for finding the data you need in Socrata.
  This module provides you with a simple struct to define SODA queries.

  All of the filters and query operators defined in the
  <a href="https://dev.socrata.com/docs/filtering.html">Socrata filter docs</a>
  and in the
  <a href="https://dev.socrata.com/docs/queries/">Socrata SoQL docs</a>
  are implemented here. Each function composes a base query.
  """

  @typedoc ""
  @type t :: %__MODULE__{fourby: String.t(), state: map()}

  defstruct fourby: nil, state: %{}

  @doc """
  Creates a new query struct.
  """
  @spec new(String.t()) :: Socrata.Query.t()
  def new(fourby), do: %Socrata.Query{fourby: fourby}

  @doc """
  Adds a simple field filter to the query.

  See the <a href="https://dev.socrata.com/docs/filtering.html">Socrata simple filters docs</a>
  for more info.

  ## Example

      iex> alias Socrata.Query
      iex> Query.new("asdf-asdf") |> Query.filter("name", "whatever")
      %Socrata.Query{fourby: "asdf-asdf", state: %{"name" => "whatever"}}
  """
  @spec filter(Socrata.Query.t(), String.t(), any()) :: Socrata.Query.t()
  def filter(query, key, value) when is_binary(key) do
    q = Map.put(query.state, key, value)
    struct!(query, state: q)
  end

  @doc """
  Adds a SoQL `$select` filter to the query.

  See the general <a href="https://dev.socrata.com/docs/queries/">Socrata SoQL docs</a>
  and the <a href="https://dev.socrata.com/docs/queries/select.html">select specific docs</a>
  for more info.

  ## Example

      iex> alias Socrata.Query
      iex> Query.new("asdf-asdf") |> Query.select(~w|name location|)
      %Socrata.Query{fourby: "asdf-asdf", state: %{"$select" => "name, location"}}
  """
  @spec select(Socrata.Query.t(), list()) :: Socrata.Query.t()
  def select(query, columns) do
    cols = Enum.map(columns, & "#{&1}") |> Enum.join(", ")
    filter(query, "$select", cols)
  end

  @doc """
  Adds a SoQL `$where` filter to the query.

  See the general <a href="https://dev.socrata.com/docs/queries/">Socrata SoQL docs</a>
  and the <a href="https://dev.socrata.com/docs/queries/where.html">where specific docs</a>
  for more info.

  ## Example

      iex> alias Socrata.Query
      iex> Query.new("asdf-asdf") |> Query.where("height >= 1000")
      %Socrata.Query{fourby: "asdf-asdf", state: %{"$where" => "height >= 1000"}}
  """
  @spec where(Socrata.Query.t(), String.t()) :: Socrata.Query.t()
  def where(query, expression), do: filter(query, "$where", expression)

  @doc """
  Adds a SoQL `$order` filter to the query.

  See the general <a href="https://dev.socrata.com/docs/queries/">Socrata SoQL docs</a>
  and the <a href="https://dev.socrata.com/docs/queries/order.html">order specific docs</a>
  for more info.

  ## Example

      iex> alias Socrata.Query
      iex> Query.new("asdf-asdf") |> Query.order("name ASC")
      %Socrata.Query{fourby: "asdf-asdf", state: %{"$order" => "name ASC"}}
  """
  @spec order(Socrata.Query.t(), String.t()) :: Socrata.Query.t()
  def order(query, expression), do: filter(query, "$order", expression)

  @doc """
  Adds a SoQL `$group` filter to the query.

  See the general <a href="https://dev.socrata.com/docs/queries/">Socrata SoQL docs</a>
  and the <a href="https://dev.socrata.com/docs/queries/group.html">group specific docs</a>
  for more info.

  ## Example

      iex> alias Socrata.Query
      iex> Query.new("asdf-asdf") |> Query.select(["location", "SUM(attendees)"]) |> Query.group("location")
      %Socrata.Query{fourby: "asdf-asdf", state: %{"$select" => "location, SUM(attendees)", "$group" => "location"}}
  """
  @spec group(Socrata.Query.t(), String.t()) :: Socrata.Query.t()
  def group(query, expression), do: filter(query, "$group", expression)

  @doc """
  Adds a SoQL `$having` filter to the query.

  See the general <a href="https://dev.socrata.com/docs/queries/">Socrata SoQL docs</a>
  and the <a href="https://dev.socrata.com/docs/queries/having.html">having specific docs</a>
  for more info.

  ## Example

      iex> alias Socrata.Query
      iex> Query.new("asdf-asdf") |> Query.select(["location", "SUM(attendees) as count"]) |> Query.group("location") |> Query.having("count > 500")
      %Socrata.Query{fourby: "asdf-asdf", state: %{"$select" => "location, SUM(attendees) as count", "$group" => "location", "$having" => "count > 500"}}
  """
  @spec having(Socrata.Query.t(), String.t()) :: Socrata.Query.t()
  def having(query, expression), do: filter(query, "$having", expression)

  @doc """
  Adds a SoQL `$limit` filter to the query.

  See the general <a href="https://dev.socrata.com/docs/queries/">Socrata SoQL docs</a>
  and the <a href="https://dev.socrata.com/docs/queries/limit.html">limit specific docs</a>
  for more info.

  ## Example

      iex> alias Socrata.Query
      iex> Query.new("asdf-asdf") |> Query.limit(10)
      %Socrata.Query{fourby: "asdf-asdf", state: %{"$limit" => 10}}
  """
  @spec limit(Socrata.Query.t(), integer()) :: Socrata.Query.t()
  def limit(query, cap) when is_integer(cap), do: filter(query, "$limit", cap)

  @doc """
  Adds a SoQL `$offset` filter to the query.

  See the general <a href="https://dev.socrata.com/docs/queries/">Socrata SoQL docs</a>
  and the <a href="https://dev.socrata.com/docs/queries/offset.html">offset specific docs</a>
  for more info.

  ## Example

      iex> alias Socrata.Query
      iex> Query.new("asdf-asdf") |> Query.limit(5) |> Query.offset(10)
      %Socrata.Query{fourby: "asdf-asdf", state: %{"$limit" => 5, "$offset" => 10}}
  """
  @spec offset(Socrata.Query.t(), integer()) :: Socrata.Query.t()
  def offset(query, skip) when is_integer(skip), do: filter(query, "$offset", skip)

  @doc """
  Adds a SoQL `$q` filter to the query.

  See the general <a href="https://dev.socrata.com/docs/queries/">Socrata SoQL docs</a>
  and the <a href="https://dev.socrata.com/docs/queries/q.html">q specific docs</a>
  for more info.

  ## Example

      iex> alias Socrata.Query
      iex> Query.new("asdf-asdf") |> Query.q("a bag of words")
      %Socrata.Query{fourby: "asdf-asdf", state: %{"$q" => "a bag of words"}}
  """
  @spec q(Socrata.Query.t(), String.t()) :: Socrata.Query.t()
  def q(query, expression), do: filter(query, "$q", expression)

  @doc """
  Adds a SoQL `$query` filter to the query.

  See the general <a href="https://dev.socrata.com/docs/queries/">Socrata SoQL docs</a>
  and the <a href="https://dev.socrata.com/docs/queries/query.html">query specific docs</a>
  for more info.

  ## Example

      iex> alias Socrata.Query
      iex> Query.new("asdf-asdf") |> Query.query("SELECT name, location, SUM(attendees) as count GROUP BY location HAVING count > 500")
      %Socrata.Query{fourby: "asdf-asdf", state: %{"$query" => "SELECT name, location, SUM(attendees) as count GROUP BY location HAVING count > 500"}}
  """
  @spec query(Socrata.Query.t(), String.t()) :: Socrata.Query.t()
  def query(query, expression), do: filter(query, "$query", expression)

  @doc """
  Adds a SoQL `$$bom=true` directive to the query.

  See the general <a href="https://dev.socrata.com/docs/queries/">Socrata SoQL docs</a>
  and the <a href="https://dev.socrata.com/docs/queries/bom.html">bom specific docs</a>
  for more info.

  ## Example

      iex> alias Socrata.Query
      iex> Query.new("asdf-asdf") |> Query.ensure_bom()
      %Socrata.Query{fourby: "asdf-asdf", state: %{"$$bom" => true}}
  """
  @spec ensure_bom(Socrata.Query.t()) :: Socrata.Query.t()
  def ensure_bom(query), do: filter(query, "$$bom", true)
end
