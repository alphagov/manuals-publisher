require "fast_spec_helper"

require "publishing_api_publisher"

describe PublishingAPIPublisher do
  let(:publishing_api) { double(:publishing_api, publish: nil) }
  let(:document_id) { "12345678-9abc-def0-1234-56789abcdef0" }
  let(:document) { double(:document, id: document_id) }

  it "raises an argument error if update_type is supplied, but not a valid choice" do
    expect {
      described_class.new(
        publishing_api: publishing_api,
        entity: document,
        update_type: "reticulate-splines"
      )
    }.to raise_error(ArgumentError, "update_type 'reticulate-splines' not recognised")
  end

  it "accepts major, minor, and republish as options for update_type" do
    %w(major minor republish).each do |update_type|
      expect {
        described_class.new(
          publishing_api: publishing_api,
          entity: document,
          update_type: update_type
        )
      }.not_to raise_error
    end
  end

  it "accepts explicitly setting nil as the option for update_type" do
    expect {
      described_class.new(
        publishing_api: publishing_api,
        entity: document,
        update_type: nil
      )
    }.not_to raise_error
  end

  describe "#call" do
    context "when no explicit update_type is given" do
      subject do
        described_class.new(
          publishing_api: publishing_api,
          entity: document
        )
      end

      it "asks the publishing api to publish the document" do
        subject.call

        expect(publishing_api).to have_received(:publish).with(document_id, nil)
      end
    end

    context "when an explicit update_type is given" do
      subject do
        described_class.new(
          publishing_api: publishing_api,
          entity: document,
          update_type: "republish"
        )
      end

      it "asks the publishing api to publish the document with the specific update_type" do
        subject.call

        expect(publishing_api).to have_received(:publish).with(document_id, "republish")
      end
    end
  end
end
