require "spec_helper"

describe SearchIndexAdapter do
  let(:rummager) { double(:rummager) }

  let(:rummager_document_type_for_manual) { SearchIndexAdapter::RUMMAGER_DOCUMENT_TYPE_FOR_MANUAL }
  let(:rummager_document_type_for_section) { SectionIndexableFormatter::RUMMAGER_DOCUMENT_TYPE }

  let(:manual) {
    Manual.build(
      id: "manual-id",
      slug: "manual-slug",
      title: "manual-title",
      summary: "manual-summary",
      updated_at: Time.zone.parse("2017-01-01 00:00:00")
    )
  }

  let(:section) {
    Section.build(
      manual: manual,
      id: "section-id",
      editions: [section_edition],
    )
  }

  let(:section_edition) {
    SectionEdition.new(
      slug: "manual-slug/section-slug",
      title: "section-title",
      summary: "section-summary",
      body: "section-body"
    )
  }

  let(:removed_section) {
    Section.build(
      manual: manual,
      id: "removed-section-id",
      editions: [removed_section_edition],
    )
  }

  let(:removed_section_edition) {
    SectionEdition.new(
      slug: "manual-slug/removed-section-slug"
    )
  }

  before do
    allow(Services).to receive(:rummager).and_return(rummager)
  end

  describe "#add" do
    before do
      manual.sections = [section]
      manual.removed_sections = [removed_section]

      allow(rummager).to receive(:add_document).with(
        rummager_document_type_for_manual, anything, anything
      )
      allow(rummager).to receive(:add_document).with(
        rummager_document_type_for_section, anything, anything
      )
      allow(rummager).to receive(:delete_document).with(
        rummager_document_type_for_section, anything
      )
    end

    it "adds manual to Rummager search index" do
      expect(rummager).to receive(:add_document).with(
        rummager_document_type_for_manual,
        "/manual-slug",
        title: "manual-title",
        description: "manual-summary",
        link: "/manual-slug",
        indexable_content: "manual-summary",
        public_timestamp: manual.updated_at,
        content_store_document_type: rummager_document_type_for_manual
      )

      subject.add(manual)
    end

    it "adds all manual's sections to Rummager search index" do
      expect(rummager).to receive(:add_document).with(
        rummager_document_type_for_section,
        "/manual-slug/section-slug",
        title: "manual-title: section-title",
        description: "section-summary",
        link: "/manual-slug/section-slug",
        indexable_content: "section-body",
        public_timestamp: nil,
        content_store_document_type: rummager_document_type_for_section,
        manual: "/manual-slug"
      )

      subject.add(manual)
    end

    it "removes manual's removed_sections from Rummager search index" do
      expect(rummager).to receive(:delete_document).with(
        rummager_document_type_for_section,
        "/manual-slug/removed-section-slug"
      )

      subject.add(manual)
    end

    context "when manual slug starts with a forward-slash" do
      before do
        manual.update(slug: "/manual-slug-starting-with-forward-slash")
      end

      it "uses the slug as the path without adding another forward-slash" do
        expect(rummager).to receive(:add_document).with(
          rummager_document_type_for_manual,
          "/manual-slug-starting-with-forward-slash",
          anything
        )

        subject.add(manual)
      end
    end
  end

  describe "#remove" do
    before do
      manual.sections = [section]

      allow(rummager).to receive(:delete_document).with(
        rummager_document_type_for_manual, anything
      )
      allow(rummager).to receive(:delete_document).with(
        rummager_document_type_for_section, anything
      )
    end

    it "removes manual from Rummager search index" do
      expect(rummager).to receive(:delete_document).with(
        rummager_document_type_for_manual,
        "/manual-slug",
      )

      subject.remove(manual)
    end

    it "removes all manual's sections from Rummager search index" do
      expect(rummager).to receive(:delete_document).with(
        rummager_document_type_for_section,
        "/manual-slug/section-slug",
      )

      subject.remove(manual)
    end
  end
end
