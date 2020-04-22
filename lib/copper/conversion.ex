defmodule Copper.Conversion do
  @moduledoc """
  Provides currency conversion to Copper.
  """
  alias Copper.Money
  alias Copper.Currency
  alias Copper.ExchangeAccess

  @doc """
  Convert a given Money struct to another currency, resulting in a new Money struct.

  ## Examples
      iex> Conversion.convert(%Money{amount: 10, fraction: 45, currency: :USD}, :BRL)
      {:ok, %Money{amount: 55, fraction: 54, currency: :BRL}}
  """
  def convert(from_money = %Money{currency: from_currency}, to_currency) do
    case ExchangeAccess.rate(from_currency, to_currency) do
      {:ok, rate} -> do_conversion_calculation(from_money, to_currency, rate)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def do_conversion_calculation(%Money{amount: from_amount, fraction: from_fraction, currency: from_currency}, to_currency, rate) do
    from_precision = Currency.exponent(from_currency)
    to_precision = Currency.exponent(to_currency)

    # Represents the resulting value when multiplying the integer part of the number with the rate
    {amount_from_integer_part, fraction_from_integer_part} =
      split_parts(from_amount * rate, to_precision)

    # Represents the resulting value when multiplying the decimal part of the number with the rate
    {amount_from_fractional_part, fraction_from_fractional_part} =
      split_parts(from_fraction / :math.pow(10, from_precision) * rate, to_precision)

    # The sum of the resulting fractions may be bigger than target currency decimal points and a new integer part will have to be summed
    {amount_from_sum_of_fractions, to_fraction} =
      split_parts((fraction_from_integer_part + fraction_from_fractional_part) / :math.pow(10, to_precision), to_precision)

    to_amount = amount_from_integer_part + amount_from_fractional_part + amount_from_sum_of_fractions

    {:ok, %Money{amount: to_amount, fraction: to_fraction, currency: to_currency}}
  end

  defp split_parts(number, precision) do
    integral = Kernel.trunc(number)
    fractional = Float.round((number - integral) * :math.pow(10, precision)) |> Kernel.trunc()
    {integral, fractional}
  end
end
