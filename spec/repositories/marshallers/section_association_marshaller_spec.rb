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
      section_ids: section_ids,
      "section_ids=": nil,
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

  before do
    allow(SectionRepository).to receive(:new).with(manual: manual).and_return(section_repository)
  end
end
