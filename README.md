# Copper
Copper is a data type for usage in money operations, based on the Martin Fowler's Money Pattern and with support for currencies described in ISO 4217. It can be used to represent specific quantities and used for operations such as share split and conversion between different currencies.

## Money
A structure to represent a monetary value in a currency.

Internally, it stores the value as two separated integer fields to maintain precision. For example, the decimal value 10.99 would be stored as `{amount: 10, fraction: 99}`. It also has a field for specifying the currency and to guarantee precision.

### Examples
``` Elixir
iex> Copper.Money.new(10, 99)
%Copper.Money{amount: 10, currency: :USD, fraction: 99}

iex> Copper.Money.new(10, 99, :BRL)
%Copper.Money{amount: 10, currency: :BRL, fraction: 99}
```

## Currency Conversion
To convert a currency, an external exchange rate api is queried for up-to-date conversion rates. The current amount is then multiplied by this rate and returned in a new Money object. If there is an error, the whole process is interrupted and the error is returned to the user.

### Examples
``` Elixir
iex> Copper.Conversion.convert(%Copper.Money{amount: 10, fraction: 45, currency: :USD}, :BRL)
{:ok, %Copper.Money{amount: 55, fraction: 54, currency: :BRL}}

# Some currencies do not have subunits, meaning that their fraction part is always zero.
iex> Copper.Conversion.convert(%Copper.Money{amount: 1, fraction: 25, currency: :USD}, :JPY)
{:ok, %Copper.Money{amount: 134, currency: :JPY, fraction: 0}}

# If there is an error with any of the currencies 
# (for example, trying to convert to a non-existing currency)
# the error is detected early and not external calls are made.
iex> Copper.Conversion.convert(%Copper.Money{amount: 1, fraction: 20, currency: :AAA}, :JPY)
{:error, :unknown_code}
```

## Splitting shares
A split of a Money struct can be made in two ways: in n equal parts or according to a list of ratios. In both cases a new list of Money structs is returned.

### Examples
``` Elixir
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
```

## Running
Copper can be ran in iex with the following command:
``` 
$ iex -S mix 
```

To do currency conversions, an api key may be needed to use certain exchange rates apis. Which api to use can be configured in config/config.exs and your api keys can be set in config/api_keys.exs.

## Documentation
Documentation can be viewed locally by running:
``` 
$ mix docs
$ open docs/index.html
```
