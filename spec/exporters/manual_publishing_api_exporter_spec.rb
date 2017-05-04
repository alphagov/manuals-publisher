require "spec_helper"
require "support/all_of_matcher"
require "support/govuk_content_schema_helpers"

require "manual_publishing_api_exporter"

describe ManualPublishingAPIExporter do
  subject {
    described_class.new(
      organisation,
      manual
    )
  }

  let(:publishing_api) { double(:publishing_api, put_content: nil) }
  let(:manual_renderer) { ->(_) { double(:rendered_manual, attributes: rendered_manual_attributes) } }

  let(:manual) {
    double(
      :manual,
      id: "52ab9439-95c8-4d39-9b83-0a2050a0978b",
      attributes: manual_attributes,
      sections: sections,
      has_ever_been_published?: manual_attributes[:ever_been_published],
      originally_published_at: nil,
      use_originally_published_at_for_public_timestamp?: false,
    )
  }

  let(:manual_slug) { "guidance/my-first-manual" }

  let(:sections) {
    [
      double(
        :section,
        id: "60023f27-0657-4812-9339-264f1c0fd90d",
        attributes: section_attributes,
        minor_update?: false,
        needs_exporting?: true,
      )
    ]
  }

  let(:section_attributes) {
    {
      title: "Document title",
      summary: "This is the first section",
      slug: "#{manual_slug}/first-section",
    }
  }

  let(:organisation) { FactoryGirl.build(:organisation) }

  let(:manual_attributes) {
    {
      title: "My first manual",
      summary: "This is my first manual",
      body: "#Some heading\nmanual body",
      slug: "guidance/my-first-manual",
      updated_at: Time.new(2013, 12, 31, 12, 0, 0),
      organisation_slug: "cabinet-office",
      ever_been_published: true,
    }
  }

  let(:rendered_manual_attributes) {
    {
      title: "My first manual",
      summary: "This is my first manual",
      body: "<h1>Some heading</h1>\nmanual body",
      slug: "guidance/my-first-manual",
      updated_at: Time.new(2013, 12, 31, 12, 0, 0),
      organisation_slug: "cabinet-office",
    }
  }

  let(:publication_logs) {
    [
      double(
        :publication_log,
        slug: "guidance/my-first-manual/first-section",
        title: "Document title",
        change_note: "Added more text",
        published_at: Time.new(2013, 12, 31, 12, 0, 0),
      ),
      double(
        :publication_log,
        slug: "guidance/my-first-manual",
        title: "My manual",
        change_note: "Changed manual title",
        published_at: Time.new(2013, 12, 31, 12, 30, 0),
      ),
    ]
  }

  before {
    allow(Services).to receive(:publishing_api).and_return(publishing_api)
    allow(ManualRenderer).to receive(:new).and_return(manual_renderer)
    allow(PublicationLog).to receive(:change_notes_for).and_return(publication_logs)
  }

  it "raises an argument error if update_type is supplied, but not a valid choice" do
    expect {
      described_class.new(
        organisation,
        manual,
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
        update_type: nil
      )
    }.not_to raise_error
  end

  it "exports a manual valid against the schema" do
    expect(subject.send(:exportable_attributes).to_json).to be_valid_against_schema(ManualPublishingAPIExporter::PUBLISHING_API_SCHEMA_NAME)
  end

  it "exports the serialized section attributes" do
    subject.call

    expect(publishing_api).to have_received(:put_content).with(
      "52ab9439-95c8-4d39-9b83-0a2050a0978b",
      all_of(
        hash_including(
          base_path: "/guidance/my-first-manual",
          schema_name: ManualPublishingAPIExporter::PUBLISHING_API_SCHEMA_NAME,
          document_type: ManualPublishingAPIExporter::PUBLISHING_API_DOCUMENT_TYPE,
          title: "My first manual",
          description: "This is my first manual",
          update_type: "major",
          publishing_app: "manuals-publisher",
          rendering_app: "manuals-frontend",
          routes: [
            {
              path: "/guidance/my-first-manual",
              type: "exact",
            },
            {
              path: "/guidance/my-first-manual/updates",
              type: "exact",
            }
          ],
          locale: "en",
        ),
        hash_excluding(:first_published_at, :public_updated_at)
      )
    ).once
  end

  context "when the manual has an originally_published_at date" do
    let(:previously_published_date) { 10.years.ago }
    before do
      allow(manual).to receive(:originally_published_at).and_return(previously_published_date)
    end

    it "adds it as the value for first_published_at in the serialized attributes" do
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(
          first_published_at: previously_published_date.iso8601,
        )
      )
    end

    it "adds it as the value for public_updated_at in the serialized attributes if the manual says to use it for the public timestamp" do
      allow(manual).to receive(:use_originally_published_at_for_public_timestamp?).and_return(true)
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(
          public_updated_at: previously_published_date.iso8601,
        )
      )
    end

    it "does not add it as the value for public_updated_at in the serialized attributes if the manual says not to use it for the public timestamp" do
      allow(manual).to receive(:use_originally_published_at_for_public_timestamp?).and_return(false)
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_excluding(:public_updated_at)
      )
    end
  end

  it "exports section metadata for the manual" do
    subject.call

    expect(publishing_api).to have_received(:put_content).with(
      "52ab9439-95c8-4d39-9b83-0a2050a0978b",
      hash_including(
        details: {
          body: [
            {
              content_type: "text/govspeak",
              content: "#Some heading\nmanual body",
            },
            {
              content_type: "text/html",
              content: "<h1>Some heading</h1>\nmanual body",
            },
          ],
          child_section_groups: [
            {
              title: "Contents",
              child_sections: [
                base_path: "/guidance/my-first-manual/first-section",
                title: "Document title",
                description: "This is the first section",
              ]
            }
          ],
          change_notes: [
            {
              base_path: "/guidance/my-first-manual/first-section",
              title: "Document title",
              change_note: "Added more text",
              published_at: Time.new(2013, 12, 31, 12, 0, 0).iso8601,
            },
            {
              base_path: "/guidance/my-first-manual",
              title: "My manual",
              change_note: "Changed manual title",
              published_at: Time.new(2013, 12, 31, 12, 30, 0).iso8601,
            },
          ],
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

  shared_examples_for "publishing a manual that has never been published" do
    before do
      allow(manual).to receive(:has_ever_been_published?).and_return(false)
    end

    it "exports with the update_type set to major" do
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "major")
      )
    end
  end

  shared_examples_for "obeying the provided update_type" do
    subject {
      described_class.new(
        organisation,
        manual,
        update_type: explicit_update_type
      )
    }

    context "when update_type is provided as 'republish'" do
      let(:explicit_update_type) { "republish" }
      it "exports with the update_type set to republish" do
        subject.call
        expect(publishing_api).to have_received(:put_content).with(
          "52ab9439-95c8-4d39-9b83-0a2050a0978b",
          hash_including(update_type: "republish")
        )
      end
    end

    context "when update_type is provided as 'minor'" do
      let(:explicit_update_type) { "minor" }
      it "exports with the update_type set to minor" do
        subject.call
        expect(publishing_api).to have_received(:put_content).with(
          "52ab9439-95c8-4d39-9b83-0a2050a0978b",
          hash_including(update_type: "minor")
        )
      end
    end

    context "when update_type is provided as 'major'" do
      let(:explicit_update_type) { "major" }
      it "exports with the update_type set to major" do
        subject.call
        expect(publishing_api).to have_received(:put_content).with(
          "52ab9439-95c8-4d39-9b83-0a2050a0978b",
          hash_including(update_type: "major")
        )
      end
    end
  end

  context "when no sections need exporting" do
    let(:sections) {
      [
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: false,
          needs_exporting?: false,
          has_ever_been_published?: true,
        ),
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: true,
          needs_exporting?: false,
          has_ever_been_published?: true,
        )
      ]
    }

    it "exports with the update_type set to minor" do
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "minor")
      )
    end

    it_behaves_like "publishing a manual that has never been published"
    it_behaves_like "obeying the provided update_type"
  end

  context "when one section needs exporting and it is a minor update" do
    let(:sections) {
      [
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: false,
          needs_exporting?: false,
          has_ever_been_published?: true,
        ),
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: true,
        )
      ]
    }

    it "exports with the update_type set to minor" do
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "minor")
      )
    end

    it_behaves_like "publishing a manual that has never been published"
    it_behaves_like "obeying the provided update_type"
  end

  context "when one section needs exporting and it is a minor update that has never been published" do
    let(:sections) {
      [
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: false,
          needs_exporting?: false,
          has_ever_been_published?: true,
        ),
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: false,
        )
      ]
    }

    it "exports with the update_type set to major" do
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "major")
      )
    end

    it_behaves_like "obeying the provided update_type"
  end

  context "when one section needs exporting and it is a major update" do
    let(:sections) {
      [
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: false,
          needs_exporting?: false,
          has_ever_been_published?: true,
        ),
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: false,
          needs_exporting?: true,
          has_ever_been_published?: true,
        )
      ]
    }

    it "exports with the update_type set to major" do
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "major")
      )
    end

    it_behaves_like "publishing a manual that has never been published"
    it_behaves_like "obeying the provided update_type"
  end

  context "when multiple sections need exporting, but none are major updates" do
    let(:sections) {
      [
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: true,
        ),
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: true,
        )
      ]
    }

    it "exports with the update_type set to minor" do
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "minor")
      )
    end

    it_behaves_like "publishing a manual that has never been published"
    it_behaves_like "obeying the provided update_type"
  end

  context "when multiple sections need exporting, but none are major updates, but one has never been published" do
    let(:sections) {
      [
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: true,
        ),
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: false,
        )
      ]
    }

    it "exports with the update_type set to major" do
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "major")
      )
    end
    it_behaves_like "obeying the provided update_type"
  end

  context "when multiple sections need exporting, and at least one is a major updates" do
    let(:sections) {
      [
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: false,
          needs_exporting?: true,
          has_ever_been_published?: true,
        ),
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: true,
        )
      ]
    }

    it "exports with the update_type set to major" do
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "major")
      )
    end

    it_behaves_like "publishing a manual that has never been published"
    it_behaves_like "obeying the provided update_type"
  end

  context "when multiple sections need exporting, and all are major updates" do
    let(:sections) {
      [
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: false,
          needs_exporting?: true,
          has_ever_been_published?: true,
        ),
        double(
          :section,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: section_attributes,
          minor_update?: false,
          needs_exporting?: true,
          has_ever_been_published?: true,
        )
      ]
    }

    it "exports with the update_type set to major" do
      subject.call

      expect(publishing_api).to have_received(:put_content).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "major")
      )
    end

    it_behaves_like "publishing a manual that has never been published"
    it_behaves_like "obeying the provided update_type"
  end
end
