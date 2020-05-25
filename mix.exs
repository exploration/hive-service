defmodule HiveService.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hive_service,
      version: "0.1.9-p2",
      elixir: "~> 1.7",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:httpoison, "~> 0.13"},
      {:jason, "~> 1.2"}
    ]
  end
end
