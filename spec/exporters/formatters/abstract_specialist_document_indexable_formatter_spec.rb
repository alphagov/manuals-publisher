require "formatters/abstract_specialist_document_indexable_formatter"

RSpec.shared_examples_for "a specialist document indexable formatter" do
  let(:slug) { "a-slug" }
  let(:published_at) { double(:published_at) }
  let(:publication_log_entry) { double(:publication_log_entry, published_at: published_at) }

  before do
    allow(document).to receive(:slug).and_return(slug)
    allow(PublicationLog).to receive(:change_notes_for).with(slug)
      .and_return([publication_log_entry])
  end

  it "should respond to #id" do
    expect(formatter).to respond_to(:id)
  end

  it "should respond to #indexable_attributes with a Hash" do
    expect(formatter.indexable_attributes).to be_a(Hash)
  end

  it "should respond to #type" do
    expect(formatter).to respond_to(:type)
  end

  describe "last update" do
    it "returns the latest PublicationLog published_at" do
      expect(PublicationLog).to receive(:change_notes_for).with(slug)
      expect(formatter.indexable_attributes[:last_update]).to eq(published_at)
    end
  end
end
