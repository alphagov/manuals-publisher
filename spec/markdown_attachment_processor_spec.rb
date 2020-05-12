require "spec_helper"

require "markdown_attachment_processor"

describe MarkdownAttachmentProcessor do
  subject(:renderer) { MarkdownAttachmentProcessor.new(doc) }

  let(:unprocessed_body) do
    %(
# Hi

this is my attachment [InlineAttachment:rofl.gif] 28 Feb 2014
    )
  end

  let(:processed_body) do
    %{
# Hi

this is my attachment [#{title}](#{file_url}) 28 Feb 2014
    }
  end

  let(:doc) { double(:doc, body: unprocessed_body, attachments: attachments) }

  let(:attachments) { [lol, rofl] }

  let(:title) { "My attachment ROFL" }
  let(:file_url) { "http://example.com/rofl.gif" }

  let(:rofl) do
    double(
      :attachment,
      title: title,
      filename: "rofl.gif",
      file_url: file_url,
      snippet: "[InlineAttachment:rofl.gif]",
    )
  end

  let(:lol) do
    double(
      :attachment,
      title: "My attachment LOL",
      filename: "lol.gif",
      file_url: "http://example.com/LOL",
      snippet: "[InlineAttachment:lol.gif]",
    )
  end

  describe "#body" do
    it "replaces inline attachment tags with link" do
      expect(renderer.body).to eq(processed_body)
    end

    context "when the title has some regex characters in it" do
      let(:title) { "Some people have crazy titles \\' \\1 \\2" }

      it "does multiple replacements" do
        expect(renderer.body).to eq(processed_body)
      end
    end

    context "when the attachment link appears more than once" do
      let(:unprocessed_body) do
        %(
# Hi

this is my attachment [InlineAttachment:rofl.gif] 28 Feb 2014
my attachment again [InlineAttachment:rofl.gif] 28 Feb 2014
        )
      end

      let(:processed_body) do
        %{
# Hi

this is my attachment [#{title}](#{file_url}) 28 Feb 2014
my attachment again [#{title}](#{file_url}) 28 Feb 2014
        }
      end

      it "does multiple replacements" do
        expect(renderer.body).to eq(processed_body)
      end
    end
  end
end
