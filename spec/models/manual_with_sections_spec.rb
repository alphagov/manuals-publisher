require "spec_helper"

require "manual_with_sections"

describe ManualWithSections do
  subject(:manual_with_sections) {
    ManualWithSections.new(section_builder, manual, sections: sections)
  }

  let(:manual) { double(:manual, publish: nil) }
  let(:section_builder) { double(:section_builder) }
  let(:sections) { [section] }
  let(:section) { double(:section, publish!: nil) }

  let(:id) { double(:id) }
  let(:updated_at) { double(:updated_at) }
  let(:title) { double(:title) }
  let(:summary) { double(:summary) }
  let(:organisation_slug) { double(:organisation_slug) }
  let(:state) { double(:state) }

  describe "#publish" do
    it "notifies the underlying manual" do
      manual_with_sections.publish

      expect(manual).to have_received(:publish)
    end

    context "when the manual publish succeeds" do
      before do
        allow(manual).to receive(:publish).and_yield
      end

      it "passes a block which publishes" do
        manual_with_sections.publish

        expect(section).to have_received(:publish!)
      end
    end

    context "when the manual publish does not succeed" do
      it "does not publish the sections" do
        manual_with_sections.publish

        expect(section).not_to have_received(:publish!)
      end
    end
  end

  describe "#reorder_sections" do
    let(:sections) {
      [
        alpha_section,
        beta_section,
        gamma_section,
      ]
    }

    let(:alpha_section) { double(:section, id: "alpha") }
    let(:beta_section) { double(:section, id: "beta") }
    let(:gamma_section) { double(:section, id: "gamma") }

    let(:section_order) { %w(gamma alpha beta) }

    it "reorders the sections to match the given order" do
      manual_with_sections.reorder_sections(%w(
        gamma
        alpha
        beta
      ))

      expect(manual_with_sections.sections.to_a).to eq([
        gamma_section,
        alpha_section,
        beta_section,
      ])
    end

    it "raises an error if section_order doesn't contain all IDs" do
      expect {
        manual_with_sections.reorder_sections(%w(
          alpha
          beta
        ))
      }.to raise_error(ArgumentError)
    end

    it "raises an error if section_order contains non-existent IDs" do
      expect {
        manual_with_sections.reorder_sections(%w(
          alpha
          beta
          gamma
          delta
        ))
      }.to raise_error(ArgumentError)
    end

    it "raises an error if section_order contains duplicate IDs" do
      expect {
        manual_with_sections.reorder_sections(%w(
          alpha
          beta
          gamma
          beta
        ))
      }.to raise_error(ArgumentError)
    end
  end

  describe "#remove_section" do
    subject(:manual_with_sections) {
      ManualWithSections.new(
        section_builder,
        manual,
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
