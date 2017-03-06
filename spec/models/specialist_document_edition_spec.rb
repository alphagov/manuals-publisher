require 'spec_helper'

describe SpecialistDocumentEdition do
  subject { SpecialistDocumentEdition.new }

  it 'stores data in the specialist_document_editions collection' do
    expect(subject.collection.name).to eq('specialist_document_editions')
  end
end
