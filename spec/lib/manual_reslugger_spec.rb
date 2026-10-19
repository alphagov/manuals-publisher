require "gds_api/test_helpers/content_store"

describe ManualReslugger do
  include GdsApi::TestHelpers::ContentStore

  subject(:reslugger) { described_class.new(old_slug, new_slug) }

  let(:old_slug) { "guidance/old-manual" }
  let(:new_slug) { "guidance/new-manual" }

  let!(:section) { FactoryBot.create(:section_edition, slug: "#{old_slug}/section") }
  let!(:removed_section) { FactoryBot.create(:section_edition, slug: "#{old_slug}/removed-section") }

  let!(:manual_record) do
    FactoryBot.create(:manual_record, slug: old_slug, section_uuids: [section.section_uuid]).tap do |record|
      record.editions.first.update!(removed_section_uuids: [removed_section.section_uuid])
    end
  end

  before do
    stub_content_store_does_not_have_item("/#{new_slug}")
    allow(Manual::RepublishService).to receive(:call)
  end

  describe "#call" do
    it "changes the manual's slug" do
      reslugger.call

      expect(manual_record.reload.slug).to eq(new_slug)
    end

    it "changes the slug of every edition of every section, including removed sections" do
      older_section_edition = FactoryBot.create(
        :section_edition,
        section_uuid: section.section_uuid,
        slug: "#{old_slug}/section",
      )

      reslugger.call

      expect(section.reload.slug).to eq("#{new_slug}/section")
      expect(older_section_edition.reload.slug).to eq("#{new_slug}/section")
      expect(removed_section.reload.slug).to eq("#{new_slug}/removed-section")
    end

    it "changes the slug of the manual's publication logs" do
      manual_log = FactoryBot.create(:publication_log, slug: old_slug)
      section_log = FactoryBot.create(:publication_log, slug: "#{old_slug}/section")

      reslugger.call

      expect(manual_log.reload.slug).to eq(new_slug)
      expect(section_log.reload.slug).to eq("#{new_slug}/section")
    end

    it "leaves another manual whose slug merely starts with the same text alone" do
      similar_log = FactoryBot.create(:publication_log, slug: "#{old_slug}-2/section")

      reslugger.call

      expect(similar_log.reload.slug).to eq("#{old_slug}-2/section")
    end

    it "only replaces the slug at the start of a section's path" do
      section.set(slug: "#{old_slug}/about-#{old_slug}")

      reslugger.call

      expect(section.reload.slug).to eq("#{new_slug}/about-#{old_slug}")
    end

    it "republishes the manual so the Publishing API picks up the new paths" do
      reslugger.call

      expect(Manual::RepublishService).to have_received(:call)
        .with(user: an_instance_of(User), manual_id: manual_record.manual_id)
    end

    context "when no manual has the old slug" do
      let!(:manual_record) { nil }

      it "raises an error" do
        expect { reslugger.call }.to raise_error(ManualReslugger::Error, /not found/)
      end
    end

    context "when a manual already has the new slug" do
      before { FactoryBot.create(:manual_record, slug: new_slug, manual_id: "another-manual") }

      it "raises an error and changes nothing" do
        expect { reslugger.call }.to raise_error(ManualReslugger::Error, /already exists/)
        expect(manual_record.reload.slug).to eq(old_slug)
        expect(Manual::RepublishService).not_to have_received(:call)
      end
    end

    context "when something else is already live at the new path" do
      before { stub_content_store_has_item("/#{new_slug}") }

      it "raises an error and changes nothing" do
        expect { reslugger.call }.to raise_error(ManualReslugger::Error, /content store/)
        expect(manual_record.reload.slug).to eq(old_slug)
      end
    end

    context "when the old and new slugs are the same" do
      let(:new_slug) { old_slug }

      it "raises an error" do
        expect { reslugger.call }.to raise_error(ManualReslugger::Error, /same/)
      end
    end
  end
end
