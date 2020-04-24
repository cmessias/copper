defmodule Copper.Split do
  @moduledoc """
  Provides splitting of arbitrary shares of a Money struct.
  """
  alias Copper.Money
  alias Copper.Currency

  @doc """
  Given a Money struct and shares, returns a list of Money structs with their values split according to the share.

  If share is a positive integer n, the function splits the value into n equals parts and returns a list of Money structs.

  If share is a list of integers, the function returns a list of Money structs where each money has value according to the share.

  ## Examples
      iex> Copper.Split.split(%Copper.Money{amount: 100, fraction: 100, currency: :USD}, [1, 2, 1])
      {:ok,
      [
        %Copper.Money{amount: 25, currency: :USD, fraction: 25},
        %Copper.Money{amount: 50, currency: :USD, fraction: 50},
        %Copper.Money{amount: 25, currency: :USD, fraction: 25}
      ]}

      # Some splits results in adjustments being made due to rounding.
      iex> Copper.Split.split(%Copper.Money{amount: 1234, fraction: 0, currency: :JPY}, 3)
      {:ok,
      [
        %Copper.Money{amount: 412, currency: :JPY, fraction: 0},
        %Copper.Money{amount: 411, currency: :JPY, fraction: 0},
        %Copper.Money{amount: 411, currency: :JPY, fraction: 0}
      ]}

      # Sometimes multiple adjustments are made.
      iex> Copper.Split.split(%Copper.Money{amount: 50, fraction: 50, currency: :USD}, [1, 1, 1, 1])
      {:ok,
      [
        %Copper.Money{amount: 12, currency: :USD, fraction: 63},
        %Copper.Money{amount: 12, currency: :USD, fraction: 63},
        %Copper.Money{amount: 12, currency: :USD, fraction: 62},
        %Copper.Money{amount: 12, currency: :USD, fraction: 62}
      ]}

      iex> Copper.Split.split(%Copper.Money{amount: 1234, fraction: 0, currency: :JPY}, -3)
      {:error, :invalid_split}
  """
  @spec split(Money.t, non_neg_integer) :: {:ok, [Money.t]} | {:error, :invalid_split}
  def split(money, share) when is_integer(share) and share > 0 do
    splits = 1..share |> Enum.map(fn _ -> 1 end)
    do_split(money, splits)
  end

  def split(_money, split) when is_integer(split) do
    {:error, :invalid_split}
  end

  @spec split(Money.t, [non_neg_integer]) :: {:ok, [Money.t]} | {:error, :invalid_split}
  def split(money, shares) when is_list(shares) do
    if Enum.any?(shares, fn split -> split <= 0 end) do
      {:error, :invalid_split}
    else
      do_split(money, shares)
    end
  end

  defp do_split(money = %Money{currency: currency}, ratios) do
    precision = Currency.exponent(currency)
    whole_amount = Money.to_whole_number(money)
    total_shares = Enum.sum(ratios)

    # Remainder here represents the missing cents due to rounding.
    {ratios, remainder} = Enum.map_reduce(ratios, whole_amount, fn ratio, remainder ->
      this_share = div(whole_amount * ratio, total_shares)
      {this_share, remainder - this_share}
    end)

    # The adjusts are made by increasing the cents of the front elements in the list as needed.
    # The fronts are chosen because of the way lists works in elixir.
    # Being implemented as linked lists, it is faster to append to the front rather than modify the list.
    {need_adjust, not_adjusted} = Enum.split(ratios, remainder)
    adjusted = do_adjust(need_adjust)

    shares = [adjusted | not_adjusted]
      |> List.flatten()
      |> Enum.map(fn amount ->
        {integer_amount, fractional_amount} = Money.split_parts(amount, precision)
        Copper.Money.new(integer_amount, fractional_amount, currency)
      end)

    {:ok, shares}
  end

  defp do_adjust([]), do: []

  defp do_adjust(need_adjust) do
    Enum.map(need_adjust, fn value -> value + 1 end)
  end
end
