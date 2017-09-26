defmodule MobileTest do
  use ExUnit.Case
  doctest Mobile

  test "greets the world" do
    assert Mobile.hello() == :world
  end
end
