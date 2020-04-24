defmodule Copper.ExchangeAccess do
  @moduledoc """
  ExchangeAccess is the module responsible for querying external apis for up-to-date conversion rates.

  Which API to query can be configured in config/config.exs. Notice that some apis require keys to be used,
  and these can be placed in config/api_keys.exs.

  This module is implemented following the Railroad Pattern
  as described by Scott Wlaschin in https://fsharpforfunandprofit.com/rop/.

  There are three flows for a request, depending if we get a cache hit, a cache miss or some error along the way.
  - If we have a cache miss, the entire pipe will be executed, querying the external api, parsing the response,
  updating the cache and lastly returning the value.
  - If we have a cache hit, the cache passes forward the information and most functions, except the last, are no-operations,
  since we already have the information we want.
  - If there is any error along the way, all remaining functions in the pipe are no-operations
  and the error is passed down until being returned to the user.

  Here is a comprehensive list of errors that can happen whenever fetching rates and what to do if they happen:
  - :invalid_key The external api endpoint configured in config.exs requires a key and the key used in the request is invalid.
  Update the config/api_keys.exs file and make sure to use a valid key. Account creation may be required to use that api.
  - :unknown_code Tried to get a conversion rate for a unknown or invalid currency.
  Make sure to use the 3-letter ISO 4217 code for currencies whenever fetching rates.
  - :not_found The api endpoint is not properly configured in config/config.exs.
  - :connect_timeout and :timeout The connection to the api could not be made within the timeouts described in config/config.exs.
  If the external api is slow, consider increasing this value.
  """
  require Logger
  alias Copper.Currency

  defp api_endpoint do
    Application.fetch_env!(:copper, :exchange_api_endpoint)
  end

  defp api_key do
    Application.fetch_env!(:copper, :api_key)
  end

  defp api_query(currency) do
    api_endpoint() <> "#{api_key()}/latest/#{currency}"
  end

  defp timeout() do
    Application.fetch_env!(:copper, :timeout)
  end

  defp recv_timeout() do
    Application.fetch_env!(:copper, :recv_timeout)
  end

  @doc """
  Fetch an up-to-date conversion rate between two currencies.

  ## Examples
      iex> Copper.ExchangeAccess.rate("USD", "BRL")
      {:ok, 5.2392}

      iex> Copper.ExchangeAccess.rate("WRONG_CURRENCY", "BRL")
      {:error, :unknown_code}
  """
  @spec rate(atom | binary, atom | binary) :: {:ok, float} | {:error, atom}
  def rate(from_currency, to_currency) do
    from_currency
    |> Currency.to_atom()
    |> validate_currencies(Currency.to_atom(to_currency))
    |> fetch_from_cache()
    |> fetch_external_if_needed()
    |> parse_response()
    |> update_cache_if_stale()
    |> get_rate(Currency.to_atom(to_currency))
  end

  defp validate_currencies(from_currency, to_currency) do
    if Currency.exist?(from_currency) && Currency.exist?(to_currency) do
      {:ok, from_currency}
    else
      {:error, :unknown_code}
    end
  end

  defp fetch_from_cache({:ok, currency}) do
    case Cachex.get(:conversion_rate, currency) do
      {:ok, nil} -> {:external, currency}
      {:ok, value} -> {:cache, value}
      {:error, reason} ->
        Logger.warn("Got an error from conversion rate cache: #{reason}")
        {:external, currency}
    end
  end

  defp fetch_from_cache({:error, reason}) do
    {:error, reason}
  end

  defp fetch_external_if_needed({:cache, value}) do
    {:cache, value}
  end

  defp fetch_external_if_needed({:external, currency}) do
    Logger.info("Calling external api for #{currency} rates")

    case HTTPoison.get(api_query(currency), [], [timeout: timeout(), recv_timeout: recv_timeout()]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Logger.info("Got response from external api: #{body}")
        {:external, body}
      {:ok, %HTTPoison.Response{status_code: 404, body: body}} ->
        Logger.info("Got error from external api: #{body}")
        {:error, :not_found}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.info("Got error from external api: #{reason}")
        {:error, reason}
    end
  end

  defp fetch_external_if_needed({:error, reason}) do
    {:error, reason}
  end

  defp parse_response({:cache, value}) do
    {:cache, value}
  end

  defp parse_response({:external, response}) do
    response = Jason.decode!(response, keys: :atoms)
    case response.result do
      "success" -> {:external, response}
      "error" -> {:error, String.replace(response.error, "-", "_") |> String.to_atom()}
    end
  end

  defp parse_response({:error, reason}) do
    {:error, reason}
  end

  defp update_cache_if_stale({:cache, value}) do
    {:ok, value}
  end

  defp update_cache_if_stale({:external, value}) do
    now = DateTime.utc_now() |> DateTime.to_unix(:second)
    cache_ttl = value.time_next_update - now

    Cachex.put(:conversion_rate, Currency.to_atom(value.base), value, ttl: :timer.seconds(cache_ttl))
    {:ok, value}
  end

  defp update_cache_if_stale({:error, reason}) do
    {:error, reason}
  end

  defp get_rate({:ok, cache}, to_currency) do
    if Map.has_key?(cache.conversion_rates, to_currency) do
      {:ok, Map.get(cache.conversion_rates, to_currency)}
    else
      {:error, :unknown_code}
    end
  end

  defp get_rate({:error, reason}, _to_currency) do
    {:error, reason}
  end
end
