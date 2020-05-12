require "spec_helper"
require "duplicate_document_finder"

describe DuplicateDocumentFinder do
  subject do
    described_class.new(io)
  end

  let(:io) { double(:io) }

  before do
    allow(io).to receive(:puts)
  end

  context "when there are multiple editions with different slugs" do
    before do
      FactoryBot.create(:section_edition, slug: "slug-1")
      FactoryBot.create(:section_edition, slug: "slug-2")
    end

    it "doesn't report them as duplicates" do
      subject.execute

      expect(io).to_not receive(:puts)
    end
  end

  context "when there are multiple editions with the same slug and same section id" do
    before do
      FactoryBot.create(:section_edition, slug: "slug", section_uuid: 1)
      FactoryBot.create(:section_edition, slug: "slug", section_uuid: 1)
    end

    it "doesn't report them as duplicates" do
      subject.execute

      expect(io).to_not receive(:puts)
    end
  end

  context "when there are multiple editions with the same slug and different section ids" do
    let!(:edition_1) do
      FactoryBot.create(:section_edition, slug: "slug", section_uuid: 1)
    end
    let!(:edition_2) do
      FactoryBot.create(:section_edition, slug: "slug", section_uuid: 2)
    end

    it "reports them as duplicates" do
      edition_1_data = [
        edition_1.slug, edition_1.section_uuid, edition_1.state, edition_1.created_at, 1
      ]
      edition_2_data = [
        edition_2.slug, edition_2.section_uuid, edition_2.state, edition_2.created_at, 1
      ]

      expect(io).to receive(:puts).with(edition_1_data.join(","))
      expect(io).to receive(:puts).with(edition_2_data.join(","))

      subject.execute
    end
  end
end
