require "spec_helper"
require "support/all_of_matcher"
require "support/govuk_content_schema_helpers"

require "section_publishing_api_exporter"

describe SectionPublishingAPIExporter do
  subject {
    described_class.new(
      organisation,
      manual,
      section
    )
  }

  let(:publishing_api) { double(:publishing_api, put_content: nil) }
  let(:section_renderer) { ->(_) { double(:rendered_section, attributes: rendered_attributes) } }

  let(:organisation) {
    Organisation.new(
      web_url: "https://www.gov.uk/government/organisations/cabinet-office",
      title: "Cabinet Office",
      abbreviation: "CO",
      content_id: "d94d63a5-ce8e-40a1-ab4c-4956eab27259"
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
      originally_published_at: nil,
      use_originally_published_at_for_public_timestamp?: false,
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

  let(:section_base_path) { "/guidance/my-first-manual/first-section" }

  let(:section) {
    double(
      :section,
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

  before {
    allow(Services).to receive(:publishing_api).and_return(publishing_api)
    allow(SectionRenderer).to receive(:new).and_return(section_renderer)
  }

  it "raises an argument error if update_type is supplied, but not a valid choice" do
    expect {
      described_class.new(
        organisation,
        manual,
        section,
        update_type: "reticulate-splines"
      )
    }.to raise_error(ArgumentError, "update_type 'reticulate-splines' not recognised")
  end

  it "accepts major, minor, and republish as options for update_type" do
    %w(major minor republish).each do |update_type|
      expect {
        described_class.new(
          organisation,
          manual,
          section,
          update_type: update_type
        )
      }.not_to raise_error
    end
  end

  it "accepts explicitly setting nil as the option for update_type" do
    expect {
      described_class.new(
        organisation,
        manual,
        section,
        update_type: nil
      )
    }.not_to raise_error
  end

  it "exports a manual_section valid against the schema" do
    expect(subject.send(:exportable_attributes).to_json).to be_valid_against_schema("manual_section")
  end

  it "exports the serialized section attributes" do
    subject.call

    expect(publishing_api).to have_received(:put_content).with(
      section.id,
      all_of(
        hash_including(
          base_path: section_base_path,
          schema_name: SectionPublishingAPIExporter::PUBLISHING_API_SCHEMA_NAME,
          document_type: SectionPublishingAPIExporter::PUBLISHING_API_DOCUMENT_TYPE,
          title: "Document title",
          description: "This is the first section",
          update_type: "minor",
          publishing_app: "manuals-publisher",
          rendering_app: "manuals-frontend",
          routes: [
            {
              path: section_base_path,
              type: "exact",
            }
          ],
        ),
        hash_excluding(:first_published_at, :public_updated_at)
      )
    )
  end

  context "when the manual has an originally_published_at date" do
    let(:previously_published_date) { 10.years.ago }
    before do
      allow(manual).to receive(:originally_published_at).and_return(previously_published_date)
    end

    it "adds it as the value for first_published_at in the serialized attributes" do
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        section.id,
        hash_including(
          first_published_at: previously_published_date.iso8601,
        )
      )
    end

    it "adds it as the value for public_updated_at in the serialized attributes if the manual says to use it for the public timestamp" do
      allow(manual).to receive(:use_originally_published_at_for_public_timestamp?).and_return(true)
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        section.id,
        hash_including(
          public_updated_at: previously_published_date.iso8601,
        )
      )
    end

    it "does not add it as the value for public_updated_at in the serialized attributes if the manual says not to use it for the public timestamp" do
      allow(manual).to receive(:use_originally_published_at_for_public_timestamp?).and_return(false)
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        section.id,
        hash_excluding(:public_updated_at)
      )
    end
  end

  context "exporting update_type correctly" do
    let(:section) {
      double(
        :section,
        id: "c19ffb7d-448c-4cc8-bece-022662ef9611",
        minor_update?: update_type_attributes[:minor_update?],
        attributes: { body: "##Some heading\nmanual section body" },
        attachments: attachments,
        has_ever_been_published?: update_type_attributes[:ever_been_published],
      )
    }

    shared_examples_for "obeying the provided update_type" do
      subject {
        described_class.new(
          organisation,
          manual,
          section,
          update_type: explicit_update_type
        )
      }

      context "when update_type is provided as 'republish'" do
        let(:explicit_update_type) { "republish" }
        it "exports with the update_type set to republish" do
          subject.call
          expect(publishing_api).to have_received(:put_content).with(
            "c19ffb7d-448c-4cc8-bece-022662ef9611",
            hash_including(update_type: "republish")
          )
        end
      end

      context "when update_type is provided as 'minor'" do
        let(:explicit_update_type) { "minor" }
        it "exports with the update_type set to minor" do
          subject.call
          expect(publishing_api).to have_received(:put_content).with(
            "c19ffb7d-448c-4cc8-bece-022662ef9611",
            hash_including(update_type: "minor")
          )
        end
      end

      context "when update_type is provided as 'major'" do
        let(:explicit_update_type) { "major" }
        it "exports with the update_type set to major" do
          subject.call
          expect(publishing_api).to have_received(:put_content).with(
            "c19ffb7d-448c-4cc8-bece-022662ef9611",
            hash_including(update_type: "major")
          )
        end
      end
    end

    context "the section is a minor update" do
      let(:update_type_attributes) do
        {
          minor_update?: true,
          ever_been_published: true,
        }
      end

      it "sets it to major if the section has never been published" do
        allow(section).to receive(:has_ever_been_published?).and_return(false)
        subject.call

        expect(publishing_api).to have_received(:put_content).with(
          "c19ffb7d-448c-4cc8-bece-022662ef9611",
          hash_including(update_type: "major")
        )
      end

      it "sets it to minor if the section has been published before" do
        subject.call

        expect(publishing_api).to have_received(:put_content).with(
          "c19ffb7d-448c-4cc8-bece-022662ef9611",
          hash_including(update_type: "minor")
        )
      end

      it_behaves_like "obeying the provided update_type"
    end

    context "the section is a major update" do
      let(:update_type_attributes) do
        {
          minor_update?: false,
          ever_been_published: true,
        }
      end

      it "sets it to major if the section has never been published" do
        update_type_attributes[:ever_been_published] = false
        subject.call

        expect(publishing_api).to have_received(:put_content).with(
          "c19ffb7d-448c-4cc8-bece-022662ef9611",
          hash_including(update_type: "major")
        )
      end

      it "sets it to major if the section has been published before" do
        subject.call

        expect(publishing_api).to have_received(:put_content).with(
          "c19ffb7d-448c-4cc8-bece-022662ef9611",
          hash_including(update_type: "major")
        )
      end

      it_behaves_like "obeying the provided update_type"
    end
  end

  it "exports section metadata for the section" do
    subject.call

    expect(publishing_api).to have_received(:put_content).with(
      section.id,
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
