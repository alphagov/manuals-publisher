require "spec_helper"
require "duplicate_document_finder"

describe DuplicateDocumentFinder do
  subject {
    described_class.new(io)
  }

  let(:io) { double(:io) }

  before {
    allow(io).to receive(:puts)
  }

  context 'when there are multiple editions with different slugs' do
    before {
      FactoryGirl.create(:section_edition, slug: 'slug-1')
      FactoryGirl.create(:section_edition, slug: 'slug-2')
    }

    it "doesn't report them as duplicates" do
      subject.execute

      expect(io).to_not receive(:puts)
    end
  end

  context 'when there are multiple editions with the same slug and same section id' do
    before {
      FactoryGirl.create(:section_edition, slug: 'slug', section_uuid: 1)
      FactoryGirl.create(:section_edition, slug: 'slug', section_uuid: 1)
    }

    it "doesn't report them as duplicates" do
      subject.execute

      expect(io).to_not receive(:puts)
    end
  end

  context 'when there are multiple editions with the same slug and different section ids' do
    let!(:edition_1) {
      FactoryGirl.create(:section_edition, slug: 'slug', section_uuid: 1)
    }
    let!(:edition_2) {
      FactoryGirl.create(:section_edition, slug: 'slug', section_uuid: 2)
    }

    it "reports them as duplicates" do
      edition_1_data = [
        edition_1.slug, edition_1.section_uuid, edition_1.state, edition_1.created_at, 1
      ]
      edition_2_data = [
        edition_2.slug, edition_2.section_uuid, edition_2.state, edition_2.created_at, 1
      ]

      expect(io).to receive(:puts).with(edition_1_data.join(','))
      expect(io).to receive(:puts).with(edition_2_data.join(','))

      subject.execute
    end
  end
end
