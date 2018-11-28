defmodule Socrata.MixProject do
  use Mix.Project

  def project do
    [
      app: :socrata,
      version: "0.1.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # distribution
      name: "Socrata",
      description: "A thin client library for Socrata",
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
end
