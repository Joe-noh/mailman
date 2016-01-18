defmodule Mailman.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mailman,
      name: "Mailman",
      source_url: "https://github.com/Joe-noh/mailman",
      homepage_url: "https://github.com/Joe-noh/mailman",
      description: desc,
      package: package,
      version: "0.2.1",
      elixir: "~> 1.0",
      deps: deps
    ]
  end

  defp desc do
    """
    Library providing a clean way of defining mailers in Elixir apps.
    Forked from kamilc/mailman.
    """
  end

  def application do
    [applications: [:ssl, :crypto, :eiconv, :gen_smtp]]
  end

  defp deps do
    [
      {:eiconv, github: "zotonic/eiconv"},
      {:gen_smtp, "~> 0.9.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      files: ["lib", "LICENSE", "README", "mix.exs"],
      maintainers: [
        "Kamil Ciemniewski <ciemniewski.kamil@gmail.com>",
        "Joe Honzawa <goflb.jh@gmail.com>"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/Joe-noh/mailman"
      }
    ]
  end
end
