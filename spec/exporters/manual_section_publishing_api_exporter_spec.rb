require "fast_spec_helper"
require "support/govuk_content_schema_helpers"

require "manual_section_publishing_api_exporter"

describe ManualSectionPublishingAPIExporter do
  subject {
    ManualSectionPublishingAPIExporter.new(
      export_recipent,
      organisation,
      document_renderer,
      manual,
      document
    )
  }

  let(:export_recipent) { double(:export_recipent, call: nil) }
  let(:document_renderer) { ->(_) { double(:rendered_document, attributes: rendered_attributes) } }

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

  let(:attachments) {
    [
      double("Attachment", attributes: {
        "content_id" => "0aa1aa33-36b9-4677-a643-52b9034a1c32",
        "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/56e7fc15ed915d037a000004/introduction-section-image.jpg",
        "title" => "introduction section image",
        "created_at" => "2015-02-11T13:45:00.000+00:00",
        "updated_at" => "2015-02-13T13:45:00.000+00:00",
      }),
      double("Attachment", attributes: {
        "content_id" => "130d2b69-e32f-437f-9caa-89a4246fbe39",
        "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/56e7fc15ed915d037a000004/introduction-section-pdf.pdf",
        "title" => "introduction section pdf",
        "created_at" => "2015-02-11T13:45:00.000+00:00",
        "updated_at" => "2015-02-13T13:45:00.000+00:00",
      }),
    ]
  }

  let(:document_base_path) { "/guidance/my-first-manual/first-section" }

  let(:document) {
    double(
      :document,
      id: "c19ffb7d-448c-4cc8-bece-022662ef9611",
      minor_update?: true,
      attributes: { body: "##Some heading\nmanual section body" },
      attachments: attachments,
      has_ever_been_published?: true,
    )
  }

  let(:rendered_attributes) {
    {
      title: "Document title",
      summary: "This is the first section",
      slug: "guidance/my-first-manual/first-section",
      body: "<h1>Some heading</h1>\nmanual section body",
      updated_at: Time.new(2013, 12, 31, 12, 0, 0),
    }
  }

  it "exports a manual_section valid against the schema" do
    expect(subject.send(:exportable_attributes).to_json).to be_valid_against_schema("manual_section")
  end

  it "exports the serialized document attributes" do
    subject.call

    expect(export_recipent).to have_received(:call).with(
      document.id,
      all_of(
        hash_including(
          base_path: document_base_path,
          schema_name: "manual_section",
          document_type: "manual_section",
          title: "Document title",
          description: "This is the first section",
          update_type: "minor",
          publishing_app: "manuals-publisher",
          rendering_app: "manuals-frontend",
          routes: [
            {
              path: document_base_path,
              type: "exact",
            }
          ],
        ),
        hash_excluding(:public_updated_at)
      )
    )
  end

  context "exporting update_type correctly" do
    let(:document) {
      double(
        :document,
        id: "c19ffb7d-448c-4cc8-bece-022662ef9611",
        minor_update?: update_type_attributes[:minor_update?],
        attributes: { body: "##Some heading\nmanual section body" },
        attachments: attachments,
        has_ever_been_published?: update_type_attributes[:ever_been_published],
      )
    }

    context "the document is a minor update" do
      let(:update_type_attributes) do
        {
          minor_update?: true,
          ever_been_published: true,
        }
      end

      it "sets it to major if the document has never been published" do
        update_type_attributes[:ever_been_published] = false
        subject.call

        expect(export_recipent).to have_received(:call).with(
          "c19ffb7d-448c-4cc8-bece-022662ef9611",
          hash_including(update_type: "major")
        )
      end

      it "sets it to minor if the document has been published before" do
        subject.call

        expect(export_recipent).to have_received(:call).with(
          "c19ffb7d-448c-4cc8-bece-022662ef9611",
          hash_including(update_type: "minor")
        )
      end
    end

    context "the document is a major update" do
      let(:update_type_attributes) do
        {
          minor_update?: false,
          ever_been_published: true,
        }
      end

      it "sets it to major if the document has never been published" do
        update_type_attributes[:ever_been_published] = false
        subject.call

        expect(export_recipent).to have_received(:call).with(
          "c19ffb7d-448c-4cc8-bece-022662ef9611",
          hash_including(update_type: "major")
        )
      end

      it "sets it to major if the document has been published before" do
        subject.call

        expect(export_recipent).to have_received(:call).with(
          "c19ffb7d-448c-4cc8-bece-022662ef9611",
          hash_including(update_type: "major")
        )
      end
    end
  end

  it "exports section metadata for the document" do
    subject.call

    expect(export_recipent).to have_received(:call).with(
      document.id,
      hash_including(
        details: {
          body:
            [
              {
                content_type: "text/govspeak",
                content: "##Some heading\nmanual section body",
              },
              {
                content_type: "text/html",
                content: "<h1>Some heading</h1>\nmanual section body",
              }
            ],
          attachments: [
            {
              content_id: "0aa1aa33-36b9-4677-a643-52b9034a1c32",
              url: "https://assets.digital.cabinet-office.gov.uk/media/56e7fc15ed915d037a000004/introduction-section-image.jpg",
              title: "introduction section image",
              content_type: "application/jpg",
              created_at: "2015-02-11T13:45:00.000+00:00",
              updated_at: "2015-02-13T13:45:00.000+00:00"
            },
            {
              content_id: "130d2b69-e32f-437f-9caa-89a4246fbe39",
              url: "https://assets.digital.cabinet-office.gov.uk/media/56e7fc15ed915d037a000004/introduction-section-pdf.pdf",
              title: "introduction section pdf",
              content_type: "application/pdf",
              created_at: "2015-02-11T13:45:00.000+00:00",
              updated_at: "2015-02-13T13:45:00.000+00:00"
            }
          ],
          manual: {
            base_path: "/guidance/my-first-manual",
          },
          organisations: [
            {
              title: "Cabinet Office",
              abbreviation: "CO",
              web_url: "https://www.gov.uk/government/organisations/cabinet-office",
            }
          ],
        }
      )
    )
  end
end
