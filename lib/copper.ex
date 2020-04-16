defmodule Copper do
  @moduledoc """
  Copper is a data type for use in money operations.

  It is based on the Martin Fowler's Money Pattern and has support for currencies described in ISO 4217.

  Copper can be used to represent specific money quantities and used for operations such as share split and conversion between different currencies.

  Internally, it used integer fields to avoid loss of precision.
  """

  defstruct amount: 0, fraction: 0, currency: :USD
end
