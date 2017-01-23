require "fast_spec_helper"
require "support/all_of_matcher"
require "support/govuk_content_schema_helpers"

require "manual_publishing_api_exporter"

describe ManualPublishingAPIExporter do
  subject {
    ManualPublishingAPIExporter.new(
      export_recipent,
      organisation,
      manual_renderer,
      publication_logs_collection,
      manual
    )
  }

  let(:export_recipent) { double(:export_recipent, call: nil) }
  let(:manual_renderer) { ->(_) { double(:rendered_manual, attributes: rendered_manual_attributes) } }

  let(:manual) {
    double(
      :manual,
      id: "52ab9439-95c8-4d39-9b83-0a2050a0978b",
      attributes: manual_attributes,
      documents: documents,
      has_ever_been_published?: manual_attributes[:ever_been_published],
      originally_published_at: nil,
    )
  }

  let(:manual_slug) { "guidance/my-first-manual" }

  let(:documents) {
    [
      double(
        :document,
        id: "60023f27-0657-4812-9339-264f1c0fd90d",
        attributes: document_attributes,
        minor_update?: false,
        needs_exporting?: true,
      )
    ]
  }

  let(:document_attributes) {
    {
      title: "Document title",
      summary: "This is the first section",
      slug: "#{manual_slug}/first-section",
    }
  }

  let(:organisation) {
    {
      "web_url" => "https://www.gov.uk/government/organisations/cabinet-office",
      "title" => "Cabinet Office",
      "details" => { "abbreviation" => "CO", "content_id" => "d94d63a5-ce8e-40a1-ab4c-4956eab27259" },
    }
  }

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

  let(:publication_logs_collection) {
    double(:publication_logs, change_notes_for: publication_logs)
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

  it "exports a manual valid against the schema" do
    expect(subject.send(:exportable_attributes).to_json).to be_valid_against_schema("manual")
  end

  it "exports the serialized document attributes" do
    subject.call

    expect(export_recipent).to have_received(:call).with(
      "52ab9439-95c8-4d39-9b83-0a2050a0978b",
      all_of(
        hash_including(
          base_path: "/guidance/my-first-manual",
          schema_name: "manual",
          document_type: "manual",
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
        hash_excluding(:public_updated_at)
      )
    ).once
  end

  it "adds first_published_at and public_updated_at to the serialized attributes if the manual has an originally_published_at date" do
    previously_published_date = 10.years.ago
    allow(manual).to receive(:originally_published_at).and_return(previously_published_date)

    subject.call

    expect(export_recipent).to have_received(:call).with(
      "52ab9439-95c8-4d39-9b83-0a2050a0978b",
      hash_including(
        first_published_at: previously_published_date.iso8601,
        public_updated_at: previously_published_date.iso8601,
      )
    )
  end

  it "exports section metadata for the manual" do
    subject.call

    expect(export_recipent).to have_received(:call).with(
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
      manual_attributes[:ever_been_published] = false
    end

    it "exports with the update_type set to major" do
      subject.call

      expect(export_recipent).to have_received(:call).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "major")
      )
    end
  end

  context "when no documents need exporting" do
    let(:documents) {
      [
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: false,
          needs_exporting?: false,
          has_ever_been_published?: true,
        ),
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: true,
          needs_exporting?: false,
          has_ever_been_published?: true,
        )
      ]
    }

    it "exports with the update_type set to minor" do
      subject.call

      expect(export_recipent).to have_received(:call).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "minor")
      )
    end

    it_behaves_like "publishing a manual that has never been published"
  end

  context "when one document needs exporting and it is a minor update" do
    let(:documents) {
      [
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: false,
          needs_exporting?: false,
          has_ever_been_published?: true,
        ),
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: true,
        )
      ]
    }

    it "exports with the update_type set to minor" do
      subject.call

      expect(export_recipent).to have_received(:call).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "minor")
      )
    end

    it_behaves_like "publishing a manual that has never been published"
  end

  context "when one document needs exporting and it is a minor update that has never been published" do
    let(:documents) {
      [
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: false,
          needs_exporting?: false,
          has_ever_been_published?: true,
        ),
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: false,
        )
      ]
    }

    it "exports with the update_type set to major" do
      subject.call

      expect(export_recipent).to have_received(:call).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "major")
      )
    end
  end

  context "when one document needs exporting and it is a major update" do
    let(:documents) {
      [
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: false,
          needs_exporting?: false,
          has_ever_been_published?: true,
        ),
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: false,
          needs_exporting?: true,
          has_ever_been_published?: true,
        )
      ]
    }

    it "exports with the update_type set to major" do
      subject.call

      expect(export_recipent).to have_received(:call).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "major")
      )
    end

    it_behaves_like "publishing a manual that has never been published"
  end

  context "when multiple documents need exporting, but none are major updates" do
    let(:documents) {
      [
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: true,
        ),
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: true,
        )
      ]
    }

    it "exports with the update_type set to minor" do
      subject.call

      expect(export_recipent).to have_received(:call).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "minor")
      )
    end

    it_behaves_like "publishing a manual that has never been published"
  end

  context "when multiple documents need exporting, but none are major updates, but one has never been published" do
    let(:documents) {
      [
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: true,
        ),
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: false,
        )
      ]
    }

    it "exports with the update_type set to major" do
      subject.call

      expect(export_recipent).to have_received(:call).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "major")
      )
    end
  end

  context "when multiple documents need exporting, and at least one is a major updates" do
    let(:documents) {
      [
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: false,
          needs_exporting?: true,
          has_ever_been_published?: true,
        ),
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: true,
          needs_exporting?: true,
          has_ever_been_published?: true,
        )
      ]
    }

    it "exports with the update_type set to major" do
      subject.call

      expect(export_recipent).to have_received(:call).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "major")
      )
    end

    it_behaves_like "publishing a manual that has never been published"
  end

  context "when multiple documents need exporting, and all are major updates" do
    let(:documents) {
      [
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: false,
          needs_exporting?: true,
          has_ever_been_published?: true,
        ),
        double(
          :document,
          id: "60023f27-0657-4812-9339-264f1c0fd90d",
          attributes: document_attributes,
          minor_update?: false,
          needs_exporting?: true,
          has_ever_been_published?: true,
        )
      ]
    }

    it "exports with the update_type set to major" do
      subject.call

      expect(export_recipent).to have_received(:call).with(
        "52ab9439-95c8-4d39-9b83-0a2050a0978b",
        hash_including(update_type: "major")
      )
    end

    it_behaves_like "publishing a manual that has never been published"
  end
end
