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
      { :cowboy, git: "https://github.com/extend/cowboy", tag: "fd37fad592fc96a384bcd060696194f5fe074f6f" },
      { :cowlib, git: "https://github.com/ninenines/cowlib", tag: "d544a494af4dbc810fc9c15eaf5cc050cced1501", override: true },
      { :ranch, git: "https://github.com/ninenines/ranch", tag: "adf1822defc2b7cfdc7aca112adabfa1d614043c", override: true }
    ]
  end
end
