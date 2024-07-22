require "spec_helper"

RSpec.describe Section::RemoveService do
  let(:state) { "published" }
  let(:section_edition) { FactoryBot.create(:section_edition, state:) }
  let(:manual_record) { FactoryBot.create(:manual_record, state:, section_uuids: [section_edition.section_uuid]) }
  let(:change_note_params) { {} }
  let(:user) { User.gds_editor }

  let(:service) do
    described_class.new(
      user:,
      manual_id: manual_record.manual_id,
      section_uuid: section_edition.section_uuid,
      attributes: change_note_params,
    )
  end

  before do
    allow(OrganisationsAdapter).to receive(:find).with(manual_record.organisation_slug)
  end

  context "with a non-existant manual" do
    context "with a section id that doesn't belong to the manual" do
      let(:service) do
        described_class.new(
          user:,
          manual_id: "non-existant-id",
          section_uuid: section_edition.section_uuid,
          attributes: change_note_params,
        )
      end

      it "raises a an error and does not remove the section" do
        expect(PublishingAdapter).to_not receive(:save_draft)
        expect(PublishingAdapter).to_not receive(:discard_section)
        expect {
          service.call
        }.to raise_error(Manual::NotFoundError, "Manual ID not found: non-existant-id")
        manual = Manual.find(manual_record.manual_id, user)
        expect(manual.sections.map(&:uuid)).to eq([section_edition.section_uuid])
        expect(manual.removed_sections.map(&:uuid)).to eq([])
        expect(manual.state).to eq("published")
      end
    end
  end

  context "with a section id that doesn't belong to the manual" do
    let(:a_different_section) { FactoryBot.create(:section_edition) }
    let(:service) do
      described_class.new(
        user:,
        manual_id: manual_record.manual_id,
        section_uuid: a_different_section.section_uuid,
        attributes: change_note_params,
      )
    end

    it "raises a SectionNotFoundError and does not remove the section" do
      expect(PublishingAdapter).to_not receive(:save_draft)
      expect(PublishingAdapter).to_not receive(:discard_section)
      expect {
        service.call
      }.to raise_error(described_class::SectionNotFoundError, a_different_section.section_uuid)
      manual = Manual.find(manual_record.manual_id, user)
      expect(manual.sections.map(&:uuid)).to eq([section_edition.section_uuid])
      expect(manual.removed_sections.map(&:uuid)).to eq([])
      expect(manual.state).to eq("published")
    end
  end

  context "with invalid change_note params" do
    let(:change_note_params) do
      {
        minor_update: "0",
        change_note: "",
      }
    end

    it "does not remove the section, does not save change note, but also does not output any warnings" do
      expect(PublishingAdapter).to_not receive(:save_draft)
      expect(PublishingAdapter).to_not receive(:discard_section)
      service.call
      manual = Manual.find(manual_record.manual_id, user)
      expect(manual.sections.map(&:uuid)).to eq([section_edition.section_uuid])
      expect(manual.removed_sections.map(&:uuid)).to eq([])
      expect(manual.state).to eq("published")
      sections = SectionEdition.all_for_section(section_edition.section_uuid)
      expect(sections.count).to eq(1)
      expect(sections.first.state).to eq("published")
      expect(sections.first.minor_update).to eq(nil)
      expect(sections.first.change_note).to eq("New section added")
    end
  end

  context "with valid change_note params" do
    let(:change_note_params) do
      {
        minor_update: "0",
        change_note: "Make a change",
      }
    end

    context "when section is published with no draft" do
      it "removes the section, saves change notes as new draft, updates manual but does not discard section draft in publishing API" do
        expect(PublishingAdapter).to receive(:save_draft).with(have_attributes(id: manual_record.manual_id), include_sections: false)
        expect(PublishingAdapter).to_not receive(:discard_section)
        service.call
        manual = Manual.find(manual_record.manual_id, user)
        expect(manual.sections.map(&:uuid)).to eq([])
        expect(manual.removed_sections.map(&:uuid)).to eq([section_edition.section_uuid])
        expect(manual.state).to eq("draft")
        sections = SectionEdition.all_for_section(section_edition.section_uuid)
        expect(sections.count).to eq(2)
        expect(sections.first.state).to eq("published")
        expect(sections.first.minor_update).to eq(nil)
        expect(sections.first.change_note).to eq("New section added")
        expect(sections.second.state).to eq("draft")
        expect(sections.second.minor_update).to eq(false)
        expect(sections.second.change_note).to eq("Make a change")
      end
    end

    context "with a section published with draft" do
      let(:section_edition) { FactoryBot.create(:section_edition, state: "draft", version_number: 2) }
      let!(:previous_published_section_edition) { FactoryBot.create(:section_edition, state: "published", version_number: 1, section_uuid: section_edition.section_uuid) }

      it "removes the section, updates change notes to draft, updates manual and discards section drafts in publishing API" do
        expect(PublishingAdapter).to receive(:save_draft).with(have_attributes(id: manual_record.manual_id), include_sections: false)
        expect(PublishingAdapter).to receive(:discard_section).with(have_attributes(uuid: section_edition.section_uuid))
        service.call
        manual = Manual.find(manual_record.manual_id, user)
        expect(manual.sections.map(&:uuid)).to eq([])
        expect(manual.removed_sections.map(&:uuid)).to eq([section_edition.section_uuid])
        expect(manual.state).to eq("draft")
        sections = SectionEdition.all_for_section(section_edition.section_uuid)
        expect(sections.count).to eq(2)
        expect(sections.first.state).to eq("draft")
        expect(sections.first.minor_update).to eq(false)
        expect(sections.first.change_note).to eq("Make a change")
        expect(sections.second.state).to eq("published")
        expect(sections.second.minor_update).to eq(nil)
        expect(sections.second.change_note).to eq("New section added")
      end
    end

    context "with a section that's never been published" do
      let(:state) { "draft" }

      it "removes the section, updates change notes to draft, updates manual and discards section drafts in publishing API" do
        expect(PublishingAdapter).to receive(:save_draft).with(have_attributes(id: manual_record.manual_id), include_sections: false)
        expect(PublishingAdapter).to receive(:discard_section).with(have_attributes(uuid: section_edition.section_uuid))
        service.call
        manual = Manual.find(manual_record.manual_id, user)
        expect(manual.sections.map(&:uuid)).to eq([])
        expect(manual.removed_sections.map(&:uuid)).to eq([section_edition.section_uuid])
        expect(manual.state).to eq("draft")
        sections = SectionEdition.all_for_section(section_edition.section_uuid)
        expect(sections.count).to eq(1)
        expect(sections.first.state).to eq("draft")
        expect(sections.first.minor_update).to eq(false)
        expect(sections.first.change_note).to eq("Make a change")
      end
    end

    context "with extra section params" do
      let(:state) { "draft" }
      let(:change_note_params) do
        {
          minor_update: "0",
          change_note: "Make a change",
          title: "Sneakily try to change this",
        }
      end

      it "operates as usual and ignores any other parameters" do
        expect(PublishingAdapter).to receive(:save_draft).with(have_attributes(id: manual_record.manual_id), include_sections: false)
        expect(PublishingAdapter).to receive(:discard_section).with(have_attributes(uuid: section_edition.section_uuid))
        service.call
        manual = Manual.find(manual_record.manual_id, user)
        expect(manual.sections.map(&:uuid)).to eq([])
        expect(manual.removed_sections.map(&:uuid)).to eq([section_edition.section_uuid])
        expect(manual.state).to eq("draft")
        sections = SectionEdition.all_for_section(section_edition.section_uuid)
        expect(sections.count).to eq(1)
        expect(sections.first.state).to eq("draft")
        expect(sections.first.minor_update).to eq(false)
        expect(sections.first.change_note).to eq("Make a change")
        expect(sections.first.title).to eq(section_edition.title)
      end
    end
  end
end
