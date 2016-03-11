require "spec_helper"
require "gds_api/test_helpers/content_store"
require "manual_and_sections_redirecter"

RSpec.describe ManualAndSectionsRedirecter, :redirect do
  include GdsApi::TestHelpers::ContentStore

  let(:manual_record) { FactoryGirl.create(:manual_record, slug: "foo") }
  let(:section_1) { FactoryGirl.create(:specialist_document_edition, slug: "foo/part-1", document_id: SecureRandom.uuid, document_type: "manual") }
  let(:section_2) { FactoryGirl.create(:specialist_document_edition, slug: "foo/part-2", document_id: SecureRandom.uuid, document_type: "manual") }
  let(:section_3) { FactoryGirl.create(:specialist_document_edition, slug: "foo/part-3", document_id: SecureRandom.uuid, document_type: "manual") }
  let(:links) do
    {
      "sections" => [
        { "base_path" => "/foo/part-1" },
        { "base_path" => "/foo/part-2" },
        { "base_path" => "/foo/part-3" },
      ]
    }
  end

  let(:redirecter) { double(:redirecter) }
  let(:publishing_api) { SpecialistPublisherWiring.get(:publishing_api) }
  let(:destination) { "/bar" }
  let(:logger) { double(:logger) }

  before do
    content_store_has_item("/foo", {"links" => links})
    allow(logger).to receive(:puts)
  end

  it "publishes a redirect for the manual and redirects for each section" do
    expect(PublishingAPIRedirecter).to receive(:new)
      .with(
        publishing_api: publishing_api,
        entity: manual_record,
        redirect_to_location: destination
      ).and_return(redirecter)

    expect(PublishingAPIRedirecter).to receive(:new)
      .with(
        publishing_api: publishing_api,
        entity: section_1,
        redirect_to_location: destination
      ).and_return(redirecter)

    expect(PublishingAPIRedirecter).to receive(:new)
      .with(
        publishing_api: publishing_api,
        entity: section_2,
        redirect_to_location: destination
      ).and_return(redirecter)

    expect(PublishingAPIRedirecter).to receive(:new)
      .with(
        publishing_api: publishing_api,
        entity: section_3,
        redirect_to_location: destination
      ).and_return(redirecter)

    expect(redirecter).to receive(:call).exactly(4).times

    described_class.new(logger: logger, base_path: "/foo", destination: "/bar").redirect
  end
end
