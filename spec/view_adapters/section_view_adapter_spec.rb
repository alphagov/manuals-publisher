require "spec_helper"

RSpec.describe SectionViewAdapter do
  let(:manual) { Manual.new(title: "manual-title") }
  let(:section) { manual.build_section(title: "section-title") }

  subject do
    described_class.new(manual, section)
  end

  describe "#accepts_minor_updates?" do
    it "returns false if section is first edition and draft" do
      expect(subject).to be_draft
      expect(subject).to be_first_edition
      expect(subject.accepts_minor_updates?).to be(false)
    end

    it "returns true if section is first edition and published" do
      section.publish!
      section.save!

      expect(subject).to be_published
      expect(subject).to be_first_edition
      expect(subject.accepts_minor_updates?).to be(true)
    end

    it "returns true if section is not first edition and is draft" do
      section.publish!
      section.save!
      section.assign_attributes(title: "new-section-title")

      expect(subject).to be_draft
      expect(subject).to_not be_first_edition
      expect(subject.accepts_minor_updates?).to be(true)
    end

    it "returns true if section is not first edition and is published" do
      section.publish!
      section.save!
      section.assign_attributes(title: "new-section-title")
      section.publish!

      expect(subject).to be_published
      expect(subject).to_not be_first_edition
      expect(subject.accepts_minor_updates?).to be(true)
    end
  end
end
