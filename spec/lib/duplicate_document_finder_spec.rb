require "spec_helper"

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
    let!(:edition1) do
      FactoryBot.create(:section_edition, slug: "slug", section_uuid: 1)
    end
    let!(:edition2) do
      FactoryBot.create(:section_edition, slug: "slug", section_uuid: 2)
    end

    it "reports them as duplicates" do
      edition1_data = [
        edition1.slug, edition1.section_uuid, edition1.state, edition1.created_at, 1
      ]
      edition2_data = [
        edition2.slug, edition2.section_uuid, edition2.state, edition2.created_at, 1
      ]

      expect(io).to receive(:puts).with(edition1_data.join(","))
      expect(io).to receive(:puts).with(edition2_data.join(","))

      subject.execute
    end
  end
end
