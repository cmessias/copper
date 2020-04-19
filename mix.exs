defmodule Copper.MixProject do
  use Mix.Project

  def project do
    [
      app: :copper,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Copper, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.21.3"},
      {:cachex, "~> 3.2"},
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.2"},
    ]
  end
end
