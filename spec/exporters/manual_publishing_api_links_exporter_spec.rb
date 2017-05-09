require "spec_helper"
require "support/govuk_content_schema_helpers"

require "manual_publishing_api_links_exporter"

describe ManualPublishingAPILinksExporter do
  subject {
    ManualPublishingAPILinksExporter.new(
      organisation,
      manual
    )
  }

  let(:publishing_api) { double(:publishing_api, patch_links: nil) }

  let(:organisation) { FactoryGirl.build(:organisation) }

  let(:manual) {
    double(
      :manual,
      id: "52ab9439-95c8-4d39-9b83-0a2050a0978b",
      attributes: {
        slug: "guidance/my-first-manual",
        organisation_slug: "cabinet-office",
      },
      sections: sections,
    )
  }

  let(:sections) {
    [
      double(:section, uuid: "c19ffb7d-448c-4cc8-bece-022662ef9611"),
      double(:section, uuid: "f9c91a07-6a41-4b97-94a8-ecdc81997d49"),
    ]
  }

  before {
    allow(Services).to receive(:publishing_api).and_return(publishing_api)
  }

  it "exports links for the manual" do
    subject.call

    expect(publishing_api).to have_received(:patch_links).with(
      manual.id,
      hash_including(
        links: {
          organisations: [organisation.content_id],
          sections: %w[c19ffb7d-448c-4cc8-bece-022662ef9611 f9c91a07-6a41-4b97-94a8-ecdc81997d49],
        }
      )
    )
  end
end
