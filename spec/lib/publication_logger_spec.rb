require "spec_helper"

RSpec.describe PublicationLogger do
  describe "call" do
    it "creates a PublicationLog for each Section" do
      manual = Manual.new(slug: "manual-slug", removed_sections: [])
      section_edition = FactoryBot.create(:section_edition)
      section = Section.new(uuid: "section-id-1", latest_edition: section_edition)
      manual.sections = [section]
      expect {
        subject.call(manual)
      }.to change(PublicationLog, :count).by(1)
    end

    # It's possible to pass a nil change_note, this indicates that the section
    # update is not to be logged by the PublicationLogger
    context "when a section edition has no change note" do
      it "does not create a PublicationLog for a cloned Section" do
        manual = Manual.new(slug: "manual-slug", removed_sections: [])
        section_edition = FactoryBot.create(:section_edition)
        section = Section.new(uuid: "section-id-1", latest_edition: section_edition)
        cloned_section_edition = FactoryBot.create(:section_edition, change_note: nil)
        cloned_section = Section.new(uuid: "section-id-2", latest_edition: cloned_section_edition)
        manual.sections = [section, cloned_section]
        expect {
          subject.call(manual)
        }.to change(PublicationLog, :count).by(1)

        expect {
          PublicationLog.find_by(change_note: nil)
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context "when there are removed sections" do
      it "creates a publication log if the section has been published before" do
        latest_edition = FactoryBot.create(:section_edition, state: :draft)
        previous_edition = FactoryBot.create(:section_edition, state: :published)
        manual = Manual.new(slug: "manual-slug")
        section = Section.new(uuid: "section-id-1", latest_edition:, previous_edition:)
        manual.removed_sections = [section]

        expect { subject.call(manual) }.to change(PublicationLog, :count).by(1)
      end

      it "does not create a publication log if the section has not ever been published" do
        latest_edition =  FactoryBot.create(:section_edition)
        manual = Manual.new(slug: "manual-slug")
        section = Section.new(uuid: "section-id-1", latest_edition:, previous_edition: nil)
        manual.removed_sections = [section]

        expect { subject.call(manual) }.to change(PublicationLog, :count).by(0)
      end
    end
  end
end
