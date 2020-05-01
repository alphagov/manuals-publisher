require "spec_helper"

describe SectionPresenter do
  let(:section) { double(:section, body: "", attachments: []) }
  subject { described_class.new(section) }

  describe "#body" do
    context "a section with a footnotes div" do
      before do
        allow(section).to receive(:body).and_return('<div class="footnotes"></div>')
      end

      it "adds a title before the existing footnotes" do
        expect(subject.body).to eq(%(<h2 id="footnotes">Footnotes</h2><div class="footnotes"></div>\n))
      end
    end

    context "a section with Govspeak in the body" do
      before do
        govspeak = <<-GOVSPEAK.strip_heredoc
          $I
            This is information
          $I
        GOVSPEAK

        allow(section).to receive(:body).and_return(govspeak)
      end

      it "converts the govspeak to HTML" do
        expected_html = <<-HTML.strip_heredoc

          <div class="information">
          <p>This is information</p>
          </div>
        HTML

        expect(subject.body).to eq(expected_html)
      end
    end

    context "a section with an attachment referenced by a snippet in the body" do
      before do
        attachment = double(:attachment, title: "title", file_url: "file-url", snippet: "[snippet]")

        allow(section).to receive(:attachments).and_return([attachment])
        allow(section).to receive(:body).and_return("[snippet]")
      end

      it "replaces snippet with a link" do
        expect(subject.body).to eq("<p><a href=\"file-url\">title</a></p>\n")
      end
    end
  end
end
