defmodule Mailman.Header do
  @moduledoc "Represents a Mime-Mail header"

  defstruct name:  "", value: ""

  def from_raw({key, value}) do
    %Mailman.Header{
      name:  key,
      value: process_value(key, value)
    }
  end

  def process_value('To', value), do: String.split(value, ",")
  def process_value(_,    value), do: value
end
