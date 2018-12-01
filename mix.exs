defmodule Socrata.MixProject do
  use Mix.Project

  def project do
    [
      app: :socrata,
      version: "2.0.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # distribution
      name: "Socrata",
      description: description(),
      source_url: "https://github.com/UrbanCCD-UChicago/socrata",
      docs: [
        main: "Socrata"
      ],
      package: package()
    ]
  end

  def application, do: []

  defp deps do
    [
      {:httpoison, "~> 1.4"},

      # dev/testing deps
      {:jason, "~> 1.1.2", only: :test},
      {:csv, "~> 2.1", only: :test},

      # distribution
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp package, do: [
    files: ["lib", "mix.exs", "COPYING", "LICENSE"],
    maintainers: ["Vince Forgione"],
    licenses: ["GPL-v3"],
    links: %{
      GitHub: "https://github.com/UrbanCCD-UChicago/socrata_client"
    }
  ]

  defp description do
    """
    A thin client library for the Socrata 2 API.

    This library focuses on wrapping up query cruft into simple, composable
    functions and returning the bare HTTPoison responses to the user -- rather
    than controlling the request/response life cycle it's handed back to you
    and your application.
    """
  end
end
