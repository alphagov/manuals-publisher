require "fast_spec_helper"
require "support/govuk_content_schema_helpers"

require "manual_publishing_api_links_exporter"

describe ManualPublishingAPILinksExporter do
  subject {
    ManualPublishingAPILinksExporter.new(
      export_recipient,
      organisation,
      manual
    )
  }

  let(:export_recipient) { double(:export_recipient, call: nil) }

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
      documents: documents,
    )
  }

  let(:documents) {
    [
      double(:document, id: "c19ffb7d-448c-4cc8-bece-022662ef9611"),
      double(:document, id: "f9c91a07-6a41-4b97-94a8-ecdc81997d49"),
    ]
  }

  it "exports links for the manual" do
    subject.call

    expect(export_recipient).to have_received(:call).with(
      manual.id,
      hash_including(
        links: {
          organisations: [organisation["details"]["content_id"]],
          sections: %w[c19ffb7d-448c-4cc8-bece-022662ef9611 f9c91a07-6a41-4b97-94a8-ecdc81997d49],
        }
      )
    )
  end

  it "exports links valid against the schema" do
    expect(subject.send(:exportable_attributes).to_json).to be_valid_against_links_schema(ManualPublishingAPIExporter::PUBLISHING_API_SCHEMA_NAME)
  end
end
