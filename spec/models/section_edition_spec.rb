require 'spec_helper'

describe SectionEdition do
  subject { SectionEdition.new }

  it 'stores data in the manual_section_editions collection' do
    expect(subject.collection.name).to eq('manual_section_editions')
  end

  describe 'validation' do
    it 'is valid if section_uuid and slug are present' do
      subject.section_uuid = 'section-uuid'
      subject.slug = 'section-slug'
      expect(subject).to be_valid
    end

    it 'is invalid if section_uuid is missing' do
      subject.section_uuid = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:section_uuid]).to include("can't be blank")
    end

    it 'is invalid if slug is missing' do
      subject.slug = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:slug]).to include("can't be blank")
    end
  end

  describe '.all_for_section' do
    it 'returns all editions for a section' do
      section_1_edition_1 = FactoryGirl.create(:section_edition, section_id: 'section-1')
      section_1_edition_2 = FactoryGirl.create(:section_edition, section_id: 'section-1')
      section_2_edition = FactoryGirl.create(:section_edition, section_id: 'section-2')

      editions = SectionEdition.all_for_section('section-1')

      expect(editions).to include(section_1_edition_1)
      expect(editions).to include(section_1_edition_2)
      expect(editions).not_to include(section_2_edition)
    end
  end

  describe '.all_for_sections' do
    it 'returns all editions for sections' do
      section_1_edition = FactoryGirl.create(:section_edition, section_id: 'section-1')
      section_2_edition = FactoryGirl.create(:section_edition, section_id: 'section-2')
      section_3_edition = FactoryGirl.create(:section_edition, section_id: 'section-3')

      editions = SectionEdition.all_for_sections('section-1', 'section-2')

      expect(editions).to include(section_1_edition)
      expect(editions).to include(section_2_edition)
      expect(editions).not_to include(section_3_edition)
    end
  end
end
