defmodule UberMulti.MixProject do
  use Mix.Project

  def project do
    [
      app: :uber_multi,
      deps: deps(),
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      version: "1.0.0"
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
      {:ecto, "> 2.0.0"}
    ]
  end
end
