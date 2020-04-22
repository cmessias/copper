defmodule ConversionTest do
  use ExUnit.Case
  doctest Copper

  alias Copper.Money
  import Copper.Conversion

  test "a conversion to currencies with same precision should maintain the precision in the result" do
    {status, money} = do_conversion_calculation(%Money{amount: 10, fraction: 45, currency: :USD}, :BRL, 5.3153)
    assert status == :ok
    assert money == %Money{amount: 55, fraction: 54, currency: :BRL}
  end

  test "a conversion to currencies with different precisions should result in a Money with the precision of the target currency" do
    {status, money} = do_conversion_calculation(%Money{amount: 10, fraction: 95, currency: :USD}, :IQD, 1191)
    assert status == :ok
    assert money == %Money{amount: 13041, fraction: 450, currency: :IQD}
  end

  test "a conversion to a currency without decimal points must result in a Money with fraction = 0" do
    {status, money} = do_conversion_calculation(%Money{amount: 10, fraction: 45, currency: :USD}, :JPY, 107.75)
    assert status == :ok
    assert money == %Money{amount: 1126, fraction: 0, currency: :JPY}
  end

  test "a conversion from a currency without decimal points to a currency with decimal points should have fraction != 0" do
    {status, money} = do_conversion_calculation(%Money{amount: 12345, fraction: 0, currency: :JPY}, :USD, 0.0093)
    assert status == :ok
    assert money == %Money{amount: 114, fraction: 81, currency: :USD}
  end
end
