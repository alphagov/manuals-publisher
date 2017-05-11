require "spec_helper"

require "publishing_api_publisher"
require "gds_api_constants"

describe PublishingAPIPublisher do
  let(:publishing_api) { double(:publishing_api, publish: nil) }
  let(:section_uuid) { "12345678-9abc-def0-1234-56789abcdef0" }
  let(:section) { double(:section, id: section_uuid) }

  it "raises an argument error if update_type is supplied, but not a valid choice" do
    expect {
      described_class.new(
        entity: section,
        update_type: "reticulate-splines"
      )
    }.to raise_error(ArgumentError, "update_type 'reticulate-splines' not recognised")
  end

  it "accepts major, minor, and republish as options for update_type" do
    PublishingAPIUpdateTypes::UPDATE_TYPES.each do |update_type|
      expect {
        described_class.new(
          entity: section,
          update_type: update_type
        )
      }.not_to raise_error
    end
  end

  it "accepts explicitly setting nil as the option for update_type" do
    expect {
      described_class.new(
        entity: section,
        update_type: nil
      )
    }.not_to raise_error
  end

  describe "#call" do
    before {
      allow(Services).to receive(:publishing_api).and_return(publishing_api)
    }

    context "when no explicit update_type is given" do
      subject do
        described_class.new(
          entity: section
        )
      end

      it "asks the publishing api to publish the section" do
        subject.call

        expect(publishing_api).to have_received(:publish).with(section_uuid, nil)
      end
    end

    context "when an explicit update_type is given" do
      subject do
        described_class.new(
          entity: section,
          update_type: GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE
        )
      end

      it "asks the publishing api to publish the section with the specific update_type" do
        subject.call

        expect(publishing_api).to have_received(:publish).with(section_uuid, GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE)
      end
    end
  end
end
