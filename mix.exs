defmodule Onion.Mixfile do
  use Mix.Project

  def project do
    [app: :onion,
     version: "0.0.1",
     elixir: "~> 1.0.0",
     deps: deps]
  end

  def application do
    [
       applications: [:logger, :cowboy, :underscorex],
       mod: {Onion.Application, []}
    ]
  end

  defp deps do
    [
      { :cowboy, github: "extend/cowboy" },
      { :underscorex, git: "git@git.appforge.ru:elixir/underscorex.git"}
    ]
  end
end
