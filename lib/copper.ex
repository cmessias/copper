defmodule Copper do
  @moduledoc """
  Copper is a data type for use in money operations.

  It is based on the Martin Fowler's Money Pattern and has support for currencies described in ISO 4217.

  Copper can be used to represent specific money quantities and used for operations such as share split and conversion between different currencies.

  Internally, it uses integer fields to avoid loss of precision.
  """
  use Application

  @impl true
  def start(_type, _args) do
    Copper.Supervisor.start_link(name: Copper.Supervisor)
  end
end
