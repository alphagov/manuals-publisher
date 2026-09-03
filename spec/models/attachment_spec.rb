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
    it "propagates errors from Asset Manager" do
      client = double("client")
      error = GdsApi::HTTPNotFound.new(404)
      allow(client).to receive(:create_asset).and_raise(error)
      allow(Services).to receive(:attachment_api).and_return(client)
      attachment = Attachment.new
      expect { attachment.upload_file }.to raise_error(error)
    end
  end

  context "#save" do
    let(:edition) do
      FactoryBot.create(:section_edition)
    end

    let(:upload_file) do
      Tempfile.new("foobar.csv")
    end

    before do
      edition.attachments << attachment
      attachment.section_edition = edition
    end

    it "uploads a file as a draft before saving" do
      expect(Services.attachment_api).to receive(:create_asset)
        .with(file: upload_file, draft: true)
        .and_return("file_url" => "some/file/url", "id" => "some_file_id")

      attachment.file = upload_file
      expect(attachment.file_has_changed?).to be true

      attachment.save!

      expect(attachment.file_id).to eq("some_file_id")
      expect(attachment.file_url).to eq("some/file/url")
    end

    context "when a file has already been uploaded" do
      before do
        attachment.file_id = "old_file_id"
      end

      it "never sends a file to an existing asset" do
        allow(Services.attachment_api).to receive(:create_asset)
          .and_return("file_url" => "some/new/url", "id" => "new_file_id")
        allow(Services.attachment_api).to receive(:update_asset)

        attachment.file = upload_file
        attachment.save!

        expect(Services.attachment_api).not_to have_received(:update_asset)
          .with(anything, hash_including(:file))
      end

      it "uploads a new draft asset and points the superseded one at it" do
        expect(Services.attachment_api).to receive(:create_asset)
          .with(file: upload_file, draft: true)
          .and_return("file_url" => "some/new/url", "id" => "new_file_id")
        expect(Services.attachment_api).to receive(:update_asset)
          .with("old_file_id", replacement_id: "new_file_id")

        attachment.file = upload_file
        attachment.save!

        expect(attachment.file_id).to eq("new_file_id")
        expect(attachment.file_url).to eq("some/new/url")
      end

      it "does not persist the new asset when linking the replacement fails" do
        attachment.file_url = "some/old/url"
        attachment.save!

        allow(Services.attachment_api).to receive(:create_asset)
          .and_return("file_url" => "some/new/url", "id" => "new_file_id")
        allow(Services.attachment_api).to receive(:update_asset)
          .with("old_file_id", replacement_id: "new_file_id")
          .and_raise(GdsApi::HTTPServerError.new(500))

        attachment.file = upload_file

        expect { attachment.save! }.to raise_error(GdsApi::HTTPServerError)
        expect(attachment.reload).to have_attributes(
          file_id: "old_file_id",
          file_url: "some/old/url",
        )
      end

      it "points each superseded asset at its replacement when replaced repeatedly" do
        allow(Services.attachment_api).to receive(:create_asset)
          .and_return(
            { "file_url" => "some/new/url", "id" => "new_file_id" },
            { "file_url" => "some/newer/url", "id" => "newer_file_id" },
          )

        expect(Services.attachment_api).to receive(:update_asset)
          .with("old_file_id", replacement_id: "new_file_id")
        expect(Services.attachment_api).to receive(:update_asset)
          .with("new_file_id", replacement_id: "newer_file_id")

        attachment.file = upload_file
        attachment.save!
        attachment.file = upload_file
        attachment.save!

        expect(attachment.file_id).to eq("newer_file_id")
      end
    end
  end

  describe "#publish_file" do
    it "makes the asset public" do
      attachment.file_id = "some_file_id"

      expect(Services.attachment_api).to receive(:update_asset)
        .with("some_file_id", draft: false)

      attachment.publish_file
    end

    it "does nothing when no file has been uploaded" do
      expect(Services.attachment_api).not_to receive(:update_asset)

      attachment.publish_file
    end
  end

  describe "#content_type" do
    before do
      attachment.file_url = file_url
    end

    context "when file_url is set" do
      let(:file_url) { "http://attachment-url.pdf" }

      it "returns PDF content type" do
        expect(attachment.content_type).to eq("application/pdf")
      end
    end

    context "when file_url is not set" do
      let(:file_url) { nil }

      it "returns nil" do
        expect(attachment.content_type).to be_nil
      end
    end
  end

  describe "#to_param" do
    it "returns a string ID" do
      expect(attachment.to_param).to be_an_instance_of(String)
    end
  end
end
