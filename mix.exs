defmodule UberMulti.MixProject do
  use Mix.Project

  def project do
    [
      app: :uber_multi,
      deps: deps(),
      description: description(),
      package: package(),
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      version: "1.0.1"
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
      {:ecto, "> 2.0.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "A helper for 'Ecto.Multi.run/3' that facilitates calling functions not written for Ecto.Multi."
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mononym/uber_multi"}
    ]
  end
end
