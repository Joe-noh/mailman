defmodule Mailman.ExternalSmtpAdapter do
  @moduledoc "Adapter for sending email via external SMTP server"

  @doc "Delivers an email based on specified config"
  def deliver(config, email, message) do
    relay_config = [
      relay:    config.relay,
      username: config.username,
      password: config.password,
      port:     config.port,
      ssl:      config.ssl,
      tls:      config.tls,
      auth:     config.auth
    ]

    {email.from, email.to, message}
    |> :gen_smtp_client.send_blocking(relay_config)
    |> case do
      error = {:error, _} -> error
      _other -> {:ok, message}
    end
  end
end
