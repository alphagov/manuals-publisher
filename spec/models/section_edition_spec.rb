require "spec_helper"

describe SectionEdition do
  subject { SectionEdition.new }

  it "stores data in the manual_section_editions collection" do
    expect(subject.collection.name).to eq("manual_section_editions")
  end

  describe "validation" do
    it "is valid if section_uuid and slug are present" do
      subject.section_uuid = "section-uuid"
      subject.slug = "section-slug"
      expect(subject).to be_valid
    end

    it "is invalid if section_uuid is missing" do
      subject.section_uuid = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:section_uuid]).to include("can't be blank")
    end

    it "is invalid if slug is missing" do
      subject.slug = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:slug]).to include("can't be blank")
    end
  end

  describe ".all_for_section" do
    it "returns all editions for a section" do
      section_a_edition_one = FactoryBot.create(:section_edition, section_uuid: "section-a")
      section_a_edition_two = FactoryBot.create(:section_edition, section_uuid: "section-a")
      section_b_edition = FactoryBot.create(:section_edition, section_uuid: "section-b")

      editions = SectionEdition.all_for_section("section-a")

      expect(editions).to include(section_a_edition_one)
      expect(editions).to include(section_a_edition_two)
      expect(editions).not_to include(section_b_edition)
    end
  end

  describe ".all_for_sections" do
    it "returns all editions for sections" do
      section_a_edition = FactoryBot.create(:section_edition, section_uuid: "section-a")
      section_b_edition = FactoryBot.create(:section_edition, section_uuid: "section-b")
      section_c_edition = FactoryBot.create(:section_edition, section_uuid: "section-c")

      editions = SectionEdition.all_for_sections("section-a", "section-b")

      expect(editions).to include(section_a_edition)
      expect(editions).to include(section_b_edition)
      expect(editions).not_to include(section_c_edition)
    end
  end
end
