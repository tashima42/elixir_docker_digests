defmodule DockerDigests.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_docker_digests,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: DockerDigests]
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
      {:optimus, "0.6.1"},
      {:req, "0.5.17"}
    ]
  end
end
