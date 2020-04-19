defmodule Copper.ExchangeAccess do
  require Logger
  alias Copper.Currency

  def api_endpoint do
    Application.fetch_env!(:copper, :exchange_api_endpoint)
  end

  def api_key do
    Application.fetch_env!(:copper, :api_key)
  end

  def rate(from_currency, to_currency) do
    from_currency
    |> Currency.to_atom()
    |> fetch_from_cache()
    |> fetch_external_if_needed()
    |> parse_response()
    |> update_cache_if_stale()
    |> get_rate(Currency.to_atom(to_currency))
  end

  def fetch_from_cache(currency) do
    case Cachex.get(:conversion_rate, currency) do
      {:ok, nil} -> {:external, currency}
      {:ok, value} -> {:cache, value}
      {:error, reason} ->
        Logger.warn("Got an error from conversion rate cache: #{reason}")
        {:external, currency}
    end
  end

  def fetch_external_if_needed({:cache, value}) do
    {:cache, value}
  end

  def fetch_external_if_needed({:external, currency}) do
    Logger.info("Calling external api for #{currency} rates")

    case HTTPoison.get(api_endpoint() <> "#{api_key()}/latest/#{currency}") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Logger.info("Got response from external api: #{body}")
        {:external, body}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def fetch_external_if_needed({:error, reason}) do
    {:error, reason}
  end

  def parse_response({:cache, value}) do
    {:cache, value}
  end

  def parse_response({:error, reason}) do
    {:error, reason}
  end

  def parse_response({:external, response}) do
    response = Jason.decode!(response, [keys: :atoms])
    case response.result do
      "success" -> {:external, response}
      "error" -> {:error, String.replace(response.error, "-", "_") |> String.to_atom()}
    end
  end
  def update_cache_if_stale({:cache, value}) do
    {:ok, value}
  end

  def update_cache_if_stale({:external, value}) do
    Cachex.put(:conversion_rate, Currency.to_atom(value.base), value)
    {:ok, value}
  end

  def update_cache_if_stale({:error, reason}) do
    {:error, reason}
  end

  def get_rate({:ok, cache}, to_currency) do
    {:ok, Map.get(cache.conversion_rates, to_currency)}
  end

  def get_rate({:error, reason}, _to_currency) do
    {:error, reason}
  end

end
