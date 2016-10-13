require "fast_spec_helper"

require "manual_section_publishing_api_links_exporter"

describe ManualSectionPublishingAPILinksExporter do
  subject {
    ManualSectionPublishingAPILinksExporter.new(
      export_recipent,
      organisation,
      manual,
      document
    )
  }

  let(:export_recipent) { double(:export_recipent, call: nil) }

  let(:organisation) {
    double(:organisation,
      web_url: "https://www.gov.uk/government/organisations/cabinet-office",
      title: "Cabinet Office",
      details: double(:org_details, abbreviation: "CO", content_id: "d94d63a5-ce8e-40a1-ab4c-4956eab27259"),
    )
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

  let(:document) {
    double(
      :document,
      id: "c19ffb7d-448c-4cc8-bece-022662ef9611",
      minor_update?: true,
      attributes: { body: "##Some heading\nmanual section body" },
      attachments: []
    )
  }

  it "exports links for the document" do
    subject.call

    expect(export_recipent).to have_received(:call).with(
      document.id,
      hash_including(
        links: {
          organisations: [organisation.details.content_id],
          manual: [manual.id],
        }
      )
    )
  end
end
