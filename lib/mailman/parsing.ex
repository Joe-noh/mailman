defmodule Mailman.Parsing do
  @moduledoc "Functions for parsin mail messages into Elixir structs"

  def parse(message) when is_binary(message) do
    {:ok, parse(:mimemail.decode(message))}
  end

  @doc "Parses given mime mail and returns Email"
  def parse(raw = {_type, _subtype, header, _header_params, _body}) do
    %Mailman.Email{
      subject:     get_from_header(header, "Subject") || "",
      from:        get_from_header(header, "From") || "",
      to:          get_from_header(header, "To") || "",
      reply_to:    get_from_header(header, "reply-to") || "",
      cc:          get_from_header(header, "Cc") || "",
      bcc:         get_from_header(header, "Bcc") || "",
      attachments: get_attachments(raw),
      html:        get_html(raw) || "",
      text:        get_text(raw) || "",
      delivery:    get_delivery(header) || ""
    }
  end

  @doc "Parses the message and returns Email"
  def parse!(message) do
    case parse(message) do
      {:ok, parsed}    -> parsed
      {:error, reason} -> throw "Couldn't parse given message. #{reason}"
    end
  end

  def get_from_header([],  key) when key in ~w[To Cc Bcc], do: []

  def get_from_header([], _key), do: nil

  def get_from_header([{key, value} | _], key) when key in ~w[To Cc Bcc] do
    value |> String.split(",") |> Enum.map(&String.strip/1)
  end

  def get_from_header([{key, value} | _], key), do: value

  def get_from_header([_head | tail], key), do: get_from_header(tail, key)

  def filename_from_raw({_, _, _, header_params, _}) do
    case List.last(header_params) do
      {_, []} -> nil
      {_, params} when is_list(params) ->
        params |> get_from_header("filename")
    end
  end

  def is_raw_attachement(raw_part) do
    case filename_from_raw(raw_part) do
      nil -> false
      _   -> true
    end
  end

  def is_raw_html_part({"text", "html", _, _, _}),  do: true
  def is_raw_html_part(_), do: false

  def is_raw_plain_part({"text", "plain", _, _, _}), do: true
  def is_raw_plain_part(_), do: false

  def get_attachments(raw) do
    content_parts(raw)
    |> Enum.filter(&is_raw_attachement/1)
    |> Enum.map(&raw_to_attachement/1)
  end

  def raw_to_attachement(raw = {type, subtype, _header, _header_params, body}) do
    %Mailman.Attachment{
      file_name: filename_from_raw(raw),
      mime_type: type,
      mime_sub_type: subtype,
      data: body
   }
  end

  def content_parts(raw = {_, _, _, _, body}) when is_binary(body) do
    raw |> List.wrap |> List.flatten
  end

  def content_parts({_, _, _, _, body}) when is_list(body) do
    body |> Enum.map(&content_parts/1) |> List.flatten
  end

  def get_html(raw) do
    case Enum.find(content_parts(raw), &is_raw_html_part/1) do
      nil -> nil
      {_, _, _, _, body} -> body
    end
  end

  def get_text(raw) do
    case Enum.find(content_parts(raw), &is_raw_plain_part/1) do
      nil -> nil
      {_, _, _, _, body} -> body
    end
  end

  def get_delivery(header) do
    get_from_header(header, "Date")
  end
end
