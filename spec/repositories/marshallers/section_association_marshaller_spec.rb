require "spec_helper"

require "marshallers/section_association_marshaller"

describe SectionAssociationMarshaller do
  subject(:marshaller) {
    SectionAssociationMarshaller.new
  }

  let(:section_repository) {
    double(
      :section_repository,
      fetch: nil,
      store: nil,
    )
  }

  let(:manual) { double(:manual) }
  let(:record) {
    double(
      :record,
      document_ids: section_ids,
      "document_ids=": nil,
      removed_section_ids: removed_section_ids,
      "removed_section_ids=": nil,
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

  let(:decorator) { double(:decorator) }
  let(:decorated_manual) { double(:decorated_manual) }

  before do
    allow(SectionRepository).to receive(:new).with(manual: manual).and_return(section_repository)
    allow(SectionAssociationMarshaller::Decorator).to receive(:new).and_return(decorator)
  end

  describe "#load" do
    before do
      allow(section_repository).to receive(:fetch).
        with(section_id).and_return(section)
      allow(section_repository).to receive(:fetch).
        with(removed_section_id).and_return(removed_section)
      allow(decorator).to receive(:call).and_return(decorated_manual)
    end

    it "fetches associated sections and removed sections by ids" do
      marshaller.load(manual, record)

      expect(section_repository).to have_received(:fetch).with(section_id)
      expect(section_repository).to have_received(:fetch).
        with(removed_section_id)
    end

    it "decorates the manual with the attributes" do
      marshaller.load(manual, record)

      expect(decorator).to have_received(:call).with(manual, sections: [section], removed_sections: [removed_section])
    end

    it "returns the decorated manual" do
      expect(
        marshaller.load(manual, record)
      ).to eq(decorated_manual)
    end
  end

  describe "#dump" do
    before do
      allow(manual).to receive(:sections).and_return(sections)
      allow(manual).to receive(:removed_sections).and_return(removed_sections)
    end

    it "saves associated sections and removed sections" do
      marshaller.dump(manual, record)

      expect(section_repository).to have_received(:store).with(section)
      expect(section_repository).to have_received(:store).
        with(removed_section)
    end

    it "updates associated document ids on the record" do
      marshaller.dump(manual, record)

      expect(record).to have_received(:document_ids=).with(section_ids)
    end

    it "updates associated removed document ids on the record" do
      marshaller.dump(manual, record)

      expect(record).to have_received(:removed_section_ids=).
        with(removed_section_ids)
    end

    it "returns nil" do
      expect(marshaller.dump(manual, record)).to eq(nil)
    end
  end
end
