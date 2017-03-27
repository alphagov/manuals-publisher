require "spec_helper"

require "section_header_extractor"

describe SectionHeaderExtractor do
  subject(:header_extractor) {
    SectionHeaderExtractor.new(parser, section)
  }

  let(:section) { double(:section, body: section_body, attributes: section_attributes) }
  let(:parser) { double(:parser, call: header_metadata) }

  let(:section_body) { double(:section_body) }
  let(:section_attributes) { { body: section_body } }
  let(:header_metadata) { [header_metadatum] }
  let(:header_metadatum) { double(:header_metadatum, headers: [], to_h: serialized_metadata) }
  let(:serialized_metadata) { double(:serialized_metadata) }

  it "is a true decorator" do
    expect(section).to receive(:arbitrary_message)
    header_extractor.arbitrary_message
  end

  describe "#headers" do
    it "parses the section body with the govspeak parser" do
      header_extractor.headers

      expect(parser).to have_received(:call).with(section_body)
    end

    it "returns header metadata from Govspeak" do
      expect(header_extractor.headers).to eq(header_metadata)
    end
  end

  describe "#serialized_headers" do
    it "returns the serialized headers" do
      expect(header_extractor.serialized_headers).to eq([serialized_metadata])
    end
  end

  describe "#attributes" do
    it "returns the section attributes with header metadata added" do
      expect(header_extractor.attributes).to include(section_attributes)
      expect(header_extractor.attributes).to include(headers: [serialized_metadata])
    end
  end
end
