defmodule Onion.Mixfile do
  use Mix.Project

  def project do
    [app: :onion,
     version: "0.1.0",
     elixir: "~> 1.0.0",
     deps: deps]
  end

  def application do
    [
       applications: [:logger, :cowboy],
       mod: {Onion.Application, []}
    ]
  end

  defp deps do
    [
      { :cowboy, git: "https://github.com/extend/cowboy", branch: "1.0.x" }
    ]
  end
end
