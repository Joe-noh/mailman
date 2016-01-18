defmodule MailmanTest do
  use ExUnit.Case, async: true

  setup_all do
    Mailman.TestServer.start
    :ok
  end

  defmodule MyApp.Mailer do
    def deliver(email) do
      Mailman.deliver(email, config)
    end

    def config do
      %Mailman.Context{
        config:   %Mailman.TestConfig{},
        composer: %Mailman.EexComposeConfig{}
      }
    end
  end

  def testing_email do
    %Mailman.Email{
      subject: "Hello Mailman!",
      from:    "mailman@elixir.com",
      reply_to: "reply@example.com",
      to:   ["ciemniewski.kamil@gmail.com"],
      cc:   ["testy2#tester1234.com", "abcd@defd.com"],
      bcc:  ["1234@wsd.com"],
      data: [name: "Yo"],
      text: "Hello! <%= name %> These are Unicode: qżźół",
      html: """
<html>
<body>
 <b>Hello! <%= name %></b> These are Unicode: qżźół
</body>
</html>
      """
    }
  end

  def email_with_attachments do
    %Mailman.Email{
      subject: "Pictures!",
      from:    "mailman@elixir.com",
      reply_to: "reply@example.com",
      to:  ["ciemniewski.kamil@gmail.com", "kamil@endpoint.com"],
      cc:  [],
      bcc: [],
      attachments: [
        Mailman.Attachment.inline!("test/data/blank.png")
      ],
      text: "Pictures!",
      html: """
<html>
<body>
Pictures!
</body>
</html>
      """
    }
  end

  test "sending testing emails works" do
    assert {:ok, message} = MyApp.Mailer.deliver(testing_email)
    assert {:ok, _ } = Mailman.Email.parse(message)
  end

  test "encodes attachements properly" do
    {:ok, message} = MyApp.Mailer.deliver(email_with_attachments)
    email = Mailman.Email.parse! message

    assert email.from     == email_with_attachments.from
    assert email.reply_to == email_with_attachments.reply_to
    assert email.to       == Mailman.Render.normalize_addresses(email_with_attachments.to)
    assert email.subject  == email_with_attachments.subject
    assert email.cc       == Mailman.Render.normalize_addresses(email_with_attachments.cc)
    assert email.bcc      == Mailman.Render.normalize_addresses(email_with_attachments.bcc)
    assert email.text     == email_with_attachments.text
    assert email.html     == email_with_attachments.html
    assert_same_attachments(email, email_with_attachments)
  end

  test "the message sent queue contains the latest sent messages" do
    Mailman.TestServer.clear_deliveries
    {:ok, _} = MyApp.Mailer.deliver(email_with_attachments)

    assert (Mailman.TestServer.deliveries |> Enum.count) == 1

    {:ok, _} = MyApp.Mailer.deliver(testing_email)

    assert (Mailman.TestServer.deliveries |> Enum.count) == 2

    Mailman.TestServer.clear_deliveries

    assert (Mailman.TestServer.deliveries |> Enum.count) == 0
  end


  test "Ensure attachments are encoded and decoded properly" do
    {:ok, attachment} = "test/data/blank.png" |> Path.expand |> File.read
    {:ok, email} = Mailman.Render.render(email_with_attachments, %Mailman.EexComposeConfig{}) |> Mailman.Parsing.parse
    assert attachment == email.attachments |> hd |> Map.get(:data)
  end


  def assert_same_attachments(email1, email2) do
    assert Enum.count(email1.attachments) == Enum.count(email2.attachments)
    Enum.each email1.attachments, fn(attachment) ->
      found = Enum.find email2.attachments, fn(a) ->
        a.data == attachment.data &&
          a.mime_type == attachment.mime_type &&
          a.mime_sub_type == attachment.mime_sub_type
      end
      assert found != nil
      assert found.file_name == Path.basename(found.file_name)
    end
  end

  defmodule MyApp.ExternalTextMailer do
    def deliver(email) do
      Mailman.deliver(email, config)
    end

    def config do
      %Mailman.Context{
        config:   %Mailman.TestConfig{},
        composer: %Mailman.EexComposeConfig{
          text_file: true
        }
      }
    end
  end

  def email_with_external_text do
    %Mailman.Email{
      subject: "Hello Mailman!",
      from:    "mailman@elixir.com",
      reply_to: "reply@example.com",
      to:   ["ciemniewski.kamil@gmail.com"],
      cc:   ["testy2#tester1234.com", "abcd@defd.com"],
      bcc:  ["1234@wsd.com"],
      data: [name: "Yo"],
      text: "test/templates/email.txt.eex",
      html: """
<html>
<body>
 <b>Hello! <%= name %></b> These are Unicode: qżźół
</body>
</html>
      """
    }
  end

  test "should load text part of email from external file" do
    {:ok, message} = MyApp.ExternalTextMailer.deliver(email_with_external_text)
    email = Mailman.Email.parse!(message)
    text = email_with_external_text.text
      |> EEx.eval_file(email_with_external_text.data)

    assert email.text == text
  end

  defmodule MyApp.ExternalHTMLMailer do
    def deliver(email) do
      Mailman.deliver(email, config)
    end

    def config do
      %Mailman.Context{
        config:   %Mailman.TestConfig{},
        composer: %Mailman.EexComposeConfig{
          html_file: true
        }
      }
    end
  end

  def email_with_external_html do
    %Mailman.Email{
      subject: "Hello Mailman!",
      from:    "mailman@elixir.com",
      reply_to: "reply@example.com",
      to:   ["ciemniewski.kamil@gmail.com"],
      cc:   ["testy2#tester1234.com", "abcd@defd.com"],
      bcc:  ["1234@wsd.com"],
      data: [name: "Yo"],
      text: "Hello! <%= name %> These are Unicode: qżźół",
      html: "test/templates/email.html.eex"
    }
  end

  test "should load html part of email from external file" do
    {:ok, message} = MyApp.ExternalHTMLMailer.deliver(email_with_external_html)
    email = Mailman.Email.parse! message
    assert email.html ==
           EEx.eval_file(email_with_external_html.html,
                         email_with_external_html.data)
  end

  defmodule MyApp.ExternalTemplatesMailer do
    def deliver(email) do
      Mailman.deliver(email, config)
    end

    def config do
      %Mailman.Context{
        config:   %Mailman.TestConfig{},
        composer: %Mailman.EexComposeConfig{
          html_file: true,
          text_file: true,
          html_file_path: "test/templates/",
          text_file_path: "test/templates/"
        }
      }
    end
  end

  def email_with_template_paths do
    %Mailman.Email{
      subject: "Hello Mailman!",
      from:    "mailman@elixir.com",
      reply_to: "reply@example.com",
      to:   ["ciemniewski.kamil@gmail.com"],
      cc:   ["testy2#tester1234.com", "abcd@defd.com"],
      bcc:  ["1234@wsd.com"],
      data: [name: "Yo"],
      text: "email.txt.eex",
      html: "email.html.eex"
    }
  end

  test "should load email parts from external file based on x_file_path" do
    {:ok, message} = MyApp.ExternalTemplatesMailer.deliver(email_with_template_paths)
    email = Mailman.Email.parse!(message)

    html = "test/templates/#{email_with_template_paths.html}"
      |> EEx.eval_file(email_with_template_paths.data)
    text = "test/templates/#{email_with_template_paths.text}"
      |> EEx.eval_file(email_with_template_paths.data)

    assert email.html == html
    assert email.text == text
  end
end
