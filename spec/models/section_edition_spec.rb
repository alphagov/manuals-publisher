require 'spec_helper'

describe SectionEdition do
  subject { SectionEdition.new }

  it 'stores data in the specialist_document_editions collection' do
    expect(subject.collection.name).to eq('specialist_document_editions')
  end
end
