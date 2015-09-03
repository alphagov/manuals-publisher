require "formatters/abstract_specialist_document_indexable_formatter"

RSpec.shared_context "schema available" do
  before do
    schema = double
    symbol = "#{formatter.type}_finder_schema".to_sym
    allow(SpecialistPublisherWiring).to receive(:get).with(symbol).and_return schema
    allow(schema).to receive(:humanized_facet_value).and_return double
  end
end

RSpec.shared_examples_for "a specialist document indexable formatter" do
  describe "last update" do
    let(:public_updated_at) { double(:public_updated_at) }
    let(:updated_at)        { double(:updated_at) }

    before do
      allow(document).to receive(:updated_at).and_return(updated_at)
      allow(document.slug).to receive(:start_with?).and_return(false)
    end

    it "returns the document's public_updated_at if available" do
      allow(document).to receive(:public_updated_at).and_return(public_updated_at)
      expect(formatter.indexable_attributes[:public_timestamp]).to eq(public_updated_at)
    end

    it "returns the document's updated_at if there is no public_updated_at" do
      allow(document).to receive(:public_updated_at).and_return(nil)
      expect(formatter.indexable_attributes[:public_timestamp]).to eq(updated_at)
    end
  end
end
