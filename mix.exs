defmodule OpentelemetryFunction.MixProject do
  use Mix.Project

  def project do
    [
      app: :opentelemetry_function,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "OpentelemetryFunction",
        extras: ["README.md"]
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      package: [
        name: "opentelemetry_function",
        description: """
          This package provides functions to help propagating OpenTelemetry
          context across functions that are executed asynchronously
        """,
        maintainers: ["Glia TechMovers"],
        licenses: ["MIT"],
        links: %{
          "GitHub" => "https://github.com/salemove/opentelemetry_function",
          "OpenTelemetry Erlang" => "https://github.com/open-telemetry/opentelemetry-erlang",
          "OpenTelemetry.io" => "https://opentelemetry.io"
        },
        files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*)
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
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
      {:opentelemetry_api, "~> 1.0"},
      {:opentelemetry, "~> 1.0", only: [:test]},

      ### Dev tools

      # Static type checking tool (see Erlang Dialyzer for more info)
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},

      # Build documentation (run `mix docs`)
      {:ex_doc, "~> 0.25", only: [:dev, :test], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
