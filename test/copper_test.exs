defmodule CopperTest do
  use ExUnit.Case
  doctest Copper

  test "greets the world" do
    assert Copper.hello() == :world
  end
end
