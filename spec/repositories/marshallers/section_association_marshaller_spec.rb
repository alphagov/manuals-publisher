require "spec_helper"

require "marshallers/section_association_marshaller"

describe SectionAssociationMarshaller do
  subject(:marshaller) {
    SectionAssociationMarshaller.new(
      decorator: decorator,
    )
  }

  let(:decorator) { double(:decorator, call: nil) }

  let(:section_repository) {
    double(
      :section_repository,
      fetch: nil,
      store: nil,
    )
  }

  let(:entity) { double(:entity) }
  let(:record) {
    double(
      :record,
      document_ids: section_ids,
      "document_ids=": nil,
      removed_document_ids: removed_section_ids,
      "removed_document_ids=": nil,
    )
  }

  let(:section_id) { double(:section_id) }
  let(:section_ids) { [section_id] }
  let(:section) { double(:section, id: section_id) }
  let(:sections) { [section] }

  let(:removed_section_id) { double(:removed_section_id) }
  let(:removed_section_ids) { [removed_section_id] }
  let(:removed_section) { double(:removed_section, id: removed_section_id) }
  let(:removed_sections) { [removed_section] }

  before do
    allow(SectionRepository).to receive(:new).with(manual: entity).and_return(section_repository)
  end

  describe "#load" do
    let(:decorated_entity) { double(:decorated_entity) }

    before do
      allow(section_repository).to receive(:fetch).
        with(section_id).and_return(section)
      allow(section_repository).to receive(:fetch).
        with(removed_section_id).and_return(removed_section)
      allow(decorator).to receive(:call).and_return(decorated_entity)
    end

    it "fetches associated sections and removed sections by ids" do
      marshaller.load(entity, record)

      expect(section_repository).to have_received(:fetch).with(section_id)
      expect(section_repository).to have_received(:fetch).
        with(removed_section_id)
    end

    it "decorates the entity with the attributes" do
      marshaller.load(entity, record)

      expect(decorator).to have_received(:call).
        with(entity, sections: sections, removed_sections: removed_sections)
    end

    it "returns the decorated entity" do
      expect(
        marshaller.load(entity, record)
      ).to eq(decorated_entity)
    end
  end

  describe "#dump" do
    before do
      allow(entity).to receive(:sections).and_return(sections)
      allow(entity).to receive(:removed_sections).and_return(removed_sections)
    end

    it "saves associated sections and removed sections" do
      marshaller.dump(entity, record)

      expect(section_repository).to have_received(:store).with(section)
      expect(section_repository).to have_received(:store).
        with(removed_section)
    end

    it "updates associated document ids on the record" do
      marshaller.dump(entity, record)

      expect(record).to have_received(:document_ids=).with(section_ids)
    end

    it "updates associated removed document ids on the record" do
      marshaller.dump(entity, record)

      expect(record).to have_received(:removed_document_ids=).
        with(removed_section_ids)
    end

    it "returns nil" do
      expect(marshaller.dump(entity, record)).to eq(nil)
    end
  end
end
