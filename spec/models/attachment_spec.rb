require "spec_helper"
require "attachment"
require "services"

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

  context "#upload_file" do
    it "raises an informative exception if the asset manager service can't be found" do
      client = double('client')
      allow(client).to receive(:create_asset).and_raise(GdsApi::HTTPNotFound.new(404))
      allow(Services).to receive(:attachment_api).and_return(client)
      attachment = Attachment.new
      expect { attachment.upload_file }.to raise_error(/Error uploading file. Is the Asset Manager service available\?/)
    end
  end

  context "#save" do
    let(:edition) do
      FactoryGirl.create(:section_edition)
    end

    let(:upload_file) do
      Tempfile.new("foobar.csv")
    end

    before do
      edition.attachments << attachment
      attachment.section_edition = edition
    end

    it "uploads a file before saving" do
      expect(Services.attachment_api).to receive(:create_asset)
        .with(file: upload_file)
        .and_return("file_url" => "some/file/url", "id" => "some_file_id")

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
        expect(Services.attachment_api).to receive(:update_asset)
          .with("some_file_id", file: upload_file)
          .and_return("file_url" => "some/file/url", "id" => "some_file_id")

        attachment.file = upload_file
        expect(attachment.file_has_changed?).to be true

        attachment.save

        expect(attachment.file_id).to eq("some_file_id")
        expect(attachment.file_url).to eq("some/file/url")
      end
    end
  end
end
