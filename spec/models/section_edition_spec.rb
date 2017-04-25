require 'spec_helper'

describe SectionEdition do
  subject { SectionEdition.new }

  it 'stores data in the manual_section_editions collection' do
    expect(subject.collection.name).to eq('manual_section_editions')
  end

  describe '.two_latest_versions' do
    it 'returns two latest versions' do
      FactoryGirl.create(:section_edition, section_id: 'section-id', version_number: 1)
      FactoryGirl.create(:section_edition, section_id: 'section-id', version_number: 2)
      FactoryGirl.create(:section_edition, section_id: 'section-id', version_number: 3)

      latest_versions = SectionEdition.two_latest_versions('section-id').to_a

      expect(latest_versions.count).to eql(2)
      expect(latest_versions.first.version_number).to eql(3)
      expect(latest_versions.last.version_number).to eql(2)
    end
  end
end
