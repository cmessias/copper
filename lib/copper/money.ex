defmodule Copper.Money do
  @moduledoc """
  A structure to represent a monetary value and currency.

  Internally, it stores the value as two separated integer fields to maintain precision.
  For example, the decimal value 10.99 would be stored as amount: 10, fraction: 99.

  Also has a field for specifying the currency for the value, which can be used to
  verify the precision of this currency, for example.
  """
  defstruct amount: 0, fraction: 0, currency: :USD

  alias Copper.Money
  alias Copper.Currency

  @typedoc """
  The type that represents Money, with two integer fields for the integer and fractional parts and a currency.
  """
  @type t :: %Money{amount: integer, fraction: integer, currency: atom}

  @doc """
  Returns the default currency, configured in config/config.exs

  ## Examples
      iex> Copper.Money.default_currency
      :USD
  """
  @spec default_currency :: atom
  def default_currency() do
    Application.fetch_env!(:copper, :default_currency)
  end

  @doc """
  Given a integer and fraction part of a number, returns a Money object that represents it in the given currency.

  If the currency is not given, uses the default currency.

  ## Examples
      iex> Copper.Money.new(10, 99)
      %Copper.Money{amount: 10, currency: :USD, fraction: 99}

      iex> Copper.Money.new(10, 99, :BRL)
      %Copper.Money{amount: 10, currency: :BRL, fraction: 99}
  """
  @spec new(integer, integer) :: Copper.Money.t
  def new(amount, fraction) do
    %Money{amount: amount, fraction: fraction, currency: default_currency()}
  end

  @spec new(integer, integer, atom) :: Copper.Money.t
  def new(amount, fraction, currency) when is_atom(currency) do
    %Money{amount: amount, fraction: fraction, currency: currency}
  end

  @spec new(integer, integer, binary) :: Copper.Money.t
  def new(amount, fraction, currency) do
    %Money{amount: amount, fraction: fraction, currency: Currency.to_atom(currency)}
  end

  @doc """
  Returns a whole number that represents the given Money struct. This is meant to be used
  whenever calculations are to be made and you want to avoid losing precision, for example
  when multiplying by a conversion rate.

  ## Examples
      iex> Copper.Money.to_whole_number(%Copper.Money{amount: 125, currency: :BRL, fraction: 88})
      12588
  """
  @spec to_whole_number(Copper.Money.t) :: integer
  def to_whole_number(%Money{amount: amount, fraction: fraction, currency: currency}) do
    precision = Currency.exponent(currency)
    trunc(amount * :math.pow(10, precision) + fraction)
  end

  def split_parts(number, 0) do
    {number, 0}
  end

  @doc """
  Utility function to return a whole number back into two parts.

  ## Examples
      iex> Copper.Money.split_parts(12345, 2)
      {123, 45}

      iex> Copper.Money.split_parts(123789, 3)
      {123, 789}

      iex> Copper.Money.split_parts(123456, 0)
      {123456, 0}
  """
  @spec split_parts(integer, integer) :: {integer, integer}
  def split_parts(number, precision) do
    exponent = :math.pow(10, precision) |> trunc()
    {div(number, exponent), Integer.mod(number, exponent)}
  end
end
