require "spec_helper"
require "support/govuk_content_schema_helpers"

require "section_publishing_api_links_exporter"

describe SectionPublishingAPILinksExporter do
  subject {
    SectionPublishingAPILinksExporter.new(
      organisation,
      manual,
      section
    )
  }

  let(:publishing_api) { double(:publishing_api, patch_links: nil) }

  let(:organisation) {
    {
      "web_url" => "https://www.gov.uk/government/organisations/cabinet-office",
      "title" => "Cabinet Office",
      "details" => { "abbreviation" => "CO", "content_id" => "d94d63a5-ce8e-40a1-ab4c-4956eab27259" },
    }
  }

  let(:manual) {
    double(
      :manual,
      id: "52ab9439-95c8-4d39-9b83-0a2050a0978b",
      attributes: {
        slug: "guidance/my-first-manual",
        organisation_slug: "cabinet-office",
      },
    )
  }

  let(:section) {
    double(
      :section,
      id: "c19ffb7d-448c-4cc8-bece-022662ef9611",
      minor_update?: true,
      attributes: { body: "##Some heading\nmanual section body" },
      attachments: []
    )
  }

  before {
    allow(Services).to receive(:publishing_api_v2).and_return(publishing_api)
  }

  it "exports links for the section" do
    subject.call

    expect(publishing_api).to have_received(:patch_links).with(
      section.id,
      hash_including(
        links: {
          organisations: [organisation["details"]["content_id"]],
          manual: [manual.id],
        }
      )
    )
  end

  it "exports links valid against the schema" do
    expect(subject.send(:exportable_attributes).to_json).to be_valid_against_links_schema(SectionPublishingAPIExporter::PUBLISHING_API_SCHEMA_NAME)
  end
end
