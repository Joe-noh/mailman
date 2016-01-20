defmodule Mailman.TestingAdapter do
  @moduledoc "Implementation of the testing SMTP adapter"

  def deliver(%{store_deliveries: true}, _email, message) do
    Mailman.TestServer.register_delivery message
    {:ok, message}
  end

  def deliver(%{store_deliveries: false}, _email, message) do
    {:ok, message}
  end
end
