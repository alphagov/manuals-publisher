require "fast_spec_helper"

require "specialist_document_header_extractor"

describe SpecialistDocumentHeaderExtractor do
  subject(:header_extractor) {
    SpecialistDocumentHeaderExtractor.new(doc, parser_klass)
  }

  let(:doc)     { double(:doc, body: doc_body, attributes: doc_attributes) }
  let(:parser_klass) { double(:parser_klass, new: parser) }
  let(:parser)  { double(:parser, structured_headers: header_metadata) }

  let(:doc_body)          { double(:doc_body) }
  let(:doc_attributes)    { { body: doc_body } }
  let(:header_metadata)   { [header_metadatum] }
  let(:header_metadatum)  { double(:header_metadatum, headers: [], to_h: serialized_metadata) }
  let(:serialized_metadata) { double(:serialized_metadata) }

  it "is a true decorator" do
    expect(doc).to receive(:arbitrary_message)
    header_extractor.arbitrary_message
  end

  describe "#headers" do
    it "parses the document body with the govspeak parser" do
      header_extractor.headers

      expect(parser_klass).to have_received(:new).with(doc_body)
      expect(parser).to have_received(:structured_headers)
    end

    it "returns header metadata from Govspeak" do
      expect(header_extractor.headers).to eq(header_metadata)
    end
  end

  describe "#attributes" do
    it "returns the document attributes with header metadata added" do
      expect(header_extractor.attributes).to include(doc_attributes)
      expect(header_extractor.attributes).to include(headers: [serialized_metadata])
    end
  end
end
