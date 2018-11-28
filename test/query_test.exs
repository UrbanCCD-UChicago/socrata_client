defmodule Socrata.QueryTest do
  use ExUnit.Case, async: true

  alias Socrata.Query

  describe "filter/3" do
    test "sets a new key/value in the state map" do
      q = Query.new()
      assert q.state == %{}

      q = Query.filter(q, "new", "value")
      assert q.state == %{"new" => "value"}

      q = Query.filter(q, "another new", "value")
      assert q.state == %{"new" => "value", "another new" => "value"}
    end

    test "overwrites a key in the state map" do
      q = Query.new()
      assert q.state == %{}

      q = Query.filter(q, "new", "value")
      assert q.state == %{"new" => "value"}

      q = Query.filter(q, "new", "changed")
      assert q.state == %{"new" => "changed"}
    end
  end

  describe "select/2" do
    test "sets the $select key of the state map" do
      q =
        Query.new()
        |> Query.select(~w|name birthday|)

      assert q.state == %{"$select" => "name, birthday"}
    end

    test "converts a list of strings to a comma-joined string" do
      q =
        Query.new()
        |> Query.select(~w|name birthday|)

      assert q.state == %{"$select" => "name, birthday"}
    end

    test "stringifies columns" do
      q =
        Query.new()
        |> Query.select(~w|name birthday|a)

      assert q.state == %{"$select" => "name, birthday"}
    end
  end

  describe "where/2" do
    test "sets the $where key of the state map" do
      q =
        Query.new()
        |> Query.where("some expression")

      assert q.state == %{"$where" => "some expression"}
    end
  end

  describe "order/2" do
    test "sets the $order key of the state map" do
      q =
        Query.new()
        |> Query.order("some expression")

      assert q.state == %{"$order" => "some expression"}
    end
  end

  describe "group/2" do
    test "sets the $group key of the state map" do
      q =
        Query.new()
        |> Query.group("some expression")

      assert q.state == %{"$group" => "some expression"}
    end
  end

  describe "having/2" do
    test "sets the $having key of the state map" do
      q =
        Query.new()
        |> Query.having("some expression")

      assert q.state == %{"$having" => "some expression"}
    end
  end

  describe "limit/2" do
    test "sets the $limit key of the state map" do
      q =
        Query.new()
        |> Query.limit(10)

      assert q.state == %{"$limit" => 10}
    end
  end

  describe "offset/2" do
    test "sets the $offset key of the state map" do
      q =
        Query.new()
        |> Query.offset(10)

      assert q.state == %{"$offset" => 10}
    end
  end

  describe "q/2" do
    test "sets the $q key of the state map" do
      q =
        Query.new()
        |> Query.q("some expression")

      assert q.state == %{"$q" => "some expression"}
    end
  end

  describe "query/2" do
    test "sets the $query key of the state map" do
      q =
        Query.new()
        |> Query.query("some expression")

      assert q.state == %{"$query" => "some expression"}
    end
  end

  describe "ensure_bom/1" do
    test "sets the $$bom key of the state map to true" do
      q =
        Query.new()
        |> Query.ensure_bom()

      assert q.state == %{"$$bom" => true}
    end
  end
end
