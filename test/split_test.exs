defmodule SplitTest do
  use ExUnit.Case
  doctest Copper

  alias Copper.Split
  alias Copper.Money

  test "an even split should have an equal total amount" do
    {status, [first, second, third]} = Split.split(%Money{amount: 33, fraction: 33, currency: :USD}, 3)
    assert status == :ok
    assert first.amount == 11
    assert first.fraction == 11

    assert second.amount == 11
    assert second.fraction == 11

    assert third.amount == 11
    assert third.fraction == 11

    assert first.amount + second.amount + third.amount == 33
    assert first.fraction + second.fraction + third.fraction == 33
  end

  test "an uneven split should be adjusted so that the total amount is not changed" do
    {status, [first, second, third]} = Split.split(%Money{amount: 10, fraction: 67, currency: :USD}, [1, 1, 8])
    assert status == :ok
    assert first.amount == 1
    assert first.fraction == 7

    assert second.amount == 1
    assert second.fraction == 7

    assert third.amount == 8
    assert third.fraction == 53

    assert first.amount + second.amount + third.amount == 10
    assert first.fraction + second.fraction + third.fraction == 67
  end

  test "a split in a currency without subunits should not have fractions" do
    {status, [first, second, third]} = Split.split(%Copper.Money{amount: 1234, fraction: 0, currency: :JPY}, 3)
    assert status == :ok
    assert first.amount == 412
    assert first.fraction == 0

    assert second.amount == 411
    assert second.fraction == 0

    assert third.amount == 411
    assert third.fraction == 0

    assert first.amount + second.amount + third.amount == 1234
    assert first.fraction + second.fraction + third.fraction == 0
  end

  test "a split in a currency with a bigger exponent should have more digits in fraction" do
    {status, [first, second, third, fourth]} = Copper.Split.split(%Copper.Money{amount: 50, fraction: 500, currency: :IQD}, [1, 1, 1, 1])
    assert status == :ok
    assert first.amount == 12
    assert first.fraction == 625

    assert second.amount == 12
    assert second.fraction == 625

    assert third.amount == 12
    assert third.fraction == 625

    assert fourth.amount == 12
    assert fourth.fraction == 625

    # notice that 48 + 2500 IQD == 50.500 IQD
    assert first.amount + second.amount + third.amount + fourth.amount == 48
    assert first.fraction + second.fraction + third.fraction + fourth.fraction == 2500
  end

  test "a split with negative values should return invalid split" do
    {status, error} = Split.split(%Money{amount: 10, fraction: 67, currency: :USD}, [2, -1, 9])
    assert status == :error
    assert error == :invalid_split
  end

  test "a split with a negative split should return invalid split" do
    {status, error} = Split.split(%Money{amount: 10, fraction: 67, currency: :USD}, -1)
    assert status == :error
    assert error == :invalid_split
  end
end
