import Config

config :copper,
  exchange_api_endpoint: "https://prime.exchangerate-api.com/v5/",
  default_currency: :USD,
  timeout: 3000,
  recv_timeout: 3000

config :logger,
  compile_time_purge_matching: [
    [application: :copper, level_lower_than: :warning]
  ]

import_config "api_keys.exs"
