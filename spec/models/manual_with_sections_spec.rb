require "spec_helper"

require "manual_with_sections"

describe ManualWithSections do
  subject(:manual_with_sections) {
    ManualWithSections.new(sections: sections)
  }

  let(:sections) { [section] }
  let(:section) { double(:section, publish!: nil) }

  let(:id) { double(:id) }
  let(:updated_at) { double(:updated_at) }
  let(:title) { double(:title) }
  let(:summary) { double(:summary) }
  let(:organisation_slug) { double(:organisation_slug) }
  let(:state) { double(:state) }

  describe "#remove_section" do
    subject(:manual_with_sections) {
      ManualWithSections.new(
        sections: sections,
        removed_sections: removed_sections,
      )
    }

    let(:sections) {
      [
        section_a,
        section_b,
      ]
    }
    let(:section_a) { double(:section, id: "a") }
    let(:section_b) { double(:section, id: "b") }

    let(:removed_sections) { [section_c] }
    let(:section_c) { double(:section, id: "c") }

    it "removes the section from #sections" do
      manual_with_sections.remove_section(section_a.id)

      expect(manual_with_sections.sections.to_a).to eq([section_b])
    end

    it "adds the section to #removed_sections" do
      manual_with_sections.remove_section(section_a.id)

      expect(manual_with_sections.removed_sections.to_a).to eq(
        [
          section_c,
          section_a,
        ]
      )
    end
  end
end
