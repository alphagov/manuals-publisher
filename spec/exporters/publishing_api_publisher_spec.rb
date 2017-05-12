require "spec_helper"

require "publishing_api_publisher"
require "services"
require "gds_api_constants"

describe PublishingAPIPublisher do
  let(:publishing_api) { double(:publishing_api, publish: nil) }
  let(:section_uuid) { "12345678-9abc-def0-1234-56789abcdef0" }
  let(:section) { double(:section, id: section_uuid) }

  before do
    allow(Services).to receive(:publishing_api).and_return(publishing_api)
    allow(publishing_api).to receive(:publish)
  end

  it { is_expected.to be_a(PublishingAPIUpdateTypes) }

  describe "#call" do
    context "when no explicit update_type is given" do
      it "asks the publishing api to publish the section" do
        subject.call(
          entity: section
        )

        expect(publishing_api).to have_received(:publish).with(section_uuid, nil)
      end
    end

    context "when an explicit update_type is given" do
      it "asks the publishing api to publish the section with the specific update_type" do
        subject.call(
          entity: section,
          update_type: GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE
        )

        expect(publishing_api).to have_received(:publish).with(section_uuid, GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE)
      end
    end
  end
end
