defmodule Mailman.EexComposer do
  @moduledoc "Provides functions for rendering from Eex template files"

  def compile_part(%{html_file: true, html_file_path: path}, :html, %{html: template, data: data}) do
    path |> Path.join(template) |> EEx.eval_file(data)
  end

  def compile_part(%{html_file: false}, :html, %{html: template, data: %{}}) do
    template
  end

  def compile_part(%{html_file: false}, :html, %{html: template, data: data}) do
    EEx.eval_string(template, data)
  end

  def compile_part(%{text_file: true, text_file_path: path}, :text, %{text: template, data: data}) do
    path |> Path.join(template) |> EEx.eval_file(data)
  end

  def compile_part(%{text_file: false}, :text, %{text: template, data: %{}}) do
    template
  end

  def compile_part(%{text_file: false}, :text, %{text: template, data: data}) do
    EEx.eval_string(template, data)
  end

  def compile_part(_config, :attachment, attachment) do
    attachment.data
  end
end
