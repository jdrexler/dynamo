Code.require_file "../../test_helper", __FILE__

defmodule Dynamo::RouterTest::Macros do
  defmacro assert_quoted(left, right) do
    quote do
      assert_equal quote(hygiene: false, do: unquote(left)), unquote(right)
    end
  end
end

defmodule Dynamo::RouterTest do
  import Dynamo::RouterTest::Macros
  require Dynamo::Router, as: R
  use ExUnit::Case

  def test_split_single_segment do
    assert_equal ["foo"], R.split("/foo")
    assert_equal ["foo"], R.split("foo")
  end

  def test_split_with_more_than_one_segment do
    assert_equal ["foo", "bar"], R.split("/foo/bar")
    assert_equal ["foo", "bar"], R.split("foo/bar")
  end

  def test_split_removes_trailing_slash do
    assert_equal ["foo", "bar"], R.split("/foo/bar/")
    assert_equal ["foo", "bar"], R.split("foo/bar/")
  end

  def test_generate_match_with_literal do
    assert_quoted ["foo"], R.generate_match("/foo")
    assert_quoted ["foo"], R.generate_match("foo")
  end

  def test_generate_match_with_identifier do
    assert_quoted ["foo", id], R.generate_match("/foo/:id")
    assert_quoted ["foo", username], R.generate_match("foo/:username")
  end

  def test_generate_match_with_literal_plus_identifier do
    assert_quoted ["foo", "bar-" <> id], R.generate_match("/foo/bar-:id")
    assert_quoted ["foo", "bar" <> username], R.generate_match("foo/bar:username")
  end

  def test_generate_match_only_with_glob do
    assert_quoted bar, R.generate_match("*bar")
    assert_quoted glob, R.generate_match("/*glob")

    assert_quoted ["id-" <> _ | _] = bar, R.generate_match("id-*bar")
    assert_quoted ["id-" <> _ | _] = glob, R.generate_match("/id-*glob")
  end

  def test_generate_match_with_glob do
    assert_quoted ["foo" | bar], R.generate_match("/foo/*bar")
    assert_quoted ["foo" | glob], R.generate_match("foo/*glob")
  end

  def test_generate_match_with_literal_plus_glob do
    assert_quoted ["foo" | ["id-" <> _ | _] = bar], R.generate_match("/foo/id-*bar")
    assert_quoted ["foo" | ["id-" <> _ | _] = glob], R.generate_match("foo/id-*glob")
  end

  def test_generate_invalid_match_with_segments_after_glob do
    R.generate_match("/foo/*bar/baz")
    flunk "generate_match should have failed"
  rescue: x in [Dynamo::Router::InvalidSpec]
    "cannot have a *glob followed by other segments" = x.message
  end
end