require "spec_helper"
require "attachment"

describe Attachment do
  subject(:attachment) do
    Attachment.new(
      title: "Supporting attachment",
      filename: "document.pdf",
    )
  end

  it "generates a snippet" do
    expect(attachment.snippet).to eq("[InlineAttachment:document.pdf]")
  end

  context "#save" do
    let(:edition) do
      FactoryGirl.create(:specialist_document_edition)
    end

    let(:upload_file) do
      Tempfile.new("foobar.csv")
    end

    before do
      edition.attachments << attachment
      attachment.specialist_document_edition = edition
    end

    it "uploads a file before saving" do
      expect(AttachmentApi.client).to receive(:create_asset)
        .with(file: upload_file)
        .and_return({ "file_url" => "some/file/url", "id" => "some_file_id" })

      attachment.file = upload_file
      expect(attachment.file_has_changed?).to be true

      attachment.save

      expect(attachment.file_id).to eq("some_file_id")
      expect(attachment.file_url).to eq("some/file/url")
    end

    context "when a file has already been uploaded" do
      before do
        attachment.file_id = "some_file_id"
      end

      it "updates the uploaded file on the Attachment" do
        expect(AttachmentApi.client).to receive(:update_asset)
          .with("some_file_id", file: upload_file)
          .and_return({ "file_url" => "some/file/url", "id" => "some_file_id" })

        attachment.file = upload_file
        expect(attachment.file_has_changed?).to be true

        attachment.save

        expect(attachment.file_id).to eq("some_file_id")
        expect(attachment.file_url).to eq("some/file/url")
      end
    end
  end
end
