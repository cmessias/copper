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
      iex> Copper.Conversion.convert(%Copper.Money{amount: 10, fraction: 45, currency: :USD}, :BRL)
      {:ok, %Copper.Money{amount: 55, fraction: 54, currency: :BRL}}

      # Some currencies do not have subunits,
      # meaning that their fraction part is always zero.
      iex> Copper.Conversion.convert(%Copper.Money{amount: 1, fraction: 25, currency: :USD}, :JPY)
      {:ok, %Copper.Money{amount: 134, currency: :JPY, fraction: 0}}

      # If there is an error with any of the currencies
      # (for example, trying to convert to a non-existing currency)
      # the error is detected early and not external calls are made.
      iex> Copper.Conversion.convert(%Copper.Money{amount: 1, fraction: 20, currency: :AAA}, :JPY)
      {:error, :unknown_code}
  """
  @spec convert(Copper.Money.t, atom) :: {:ok, Copper.Money.t} | {:error, String.t}
  def convert(from_money = %Money{currency: from_currency}, to_currency) do
    case ExchangeAccess.rate(from_currency, to_currency) do
      {:ok, rate} -> do_conversion_calculation(from_money, to_currency, rate)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def do_conversion_calculation(money = %Money{currency: from_currency}, to_currency, rate) do
    from_precision = Currency.exponent(from_currency)
    to_precision = Currency.exponent(to_currency)
    whole_number = Money.to_whole_number(money)

    # Here the calculations are made with the original number converted to a integer containing both
    # the integer part and the fraction part. For example: 123.45 becomes 12245.
    # This is done to avoid rounding as much as possible.
    # With this the rounding is made only once, after the calculations, rather than through the whole process.
    {integer_part, fraction_part} = (whole_number * rate / :math.pow(10, from_precision - to_precision))
      |> Float.round()
      |> trunc()
      |> Money.split_parts(to_precision)

    {:ok, Money.new(integer_part, fraction_part, to_currency)}
  end

end
