require 'spec_helper'

describe SectionEdition do
  subject { SectionEdition.new }

  it 'stores data in the manual_section_editions collection' do
    expect(subject.collection.name).to eq('manual_section_editions')
  end
end
