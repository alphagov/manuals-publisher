require "spec_helper"
require "manual_relocator"

describe ManualRelocator do
  include GdsApi::TestHelpers::PublishingApiV2
  let(:existing_manual_id) { SecureRandom.uuid }
  let(:temp_manual_id) { SecureRandom.uuid }
  let(:existing_slug) { "guidance/real-slug" }
  let(:temp_slug) { "guidance/temporary-slug" }
  subject { described_class.new(temp_slug, existing_slug) }

  describe "#old_manual" do
    it "raises an error if the existing slug doesn't result in a manual" do
      expect {
        subject.old_manual
      }.to raise_error(RuntimeError,  "No manual found for slug '#{existing_slug}'")
    end

    it "raises an error if the existing slug maps to more than one manual" do
      ManualRecord.create(manual_id: existing_manual_id, slug: existing_slug)
      ManualRecord.create(slug: existing_slug)
      expect {
        subject.old_manual
      }.to raise_error(RuntimeError,  "More than one manual found for slug '#{existing_slug}'")
    end
  end

  describe "#new_manual" do
    it "raises an error if the existing slug doesn't result in a manual" do
      expect {
        subject.new_manual
      }.to raise_error(RuntimeError,  "No manual found for slug '#{temp_slug}'")
    end

    it "raises an error if the existing slug maps to more than one manual" do
      ManualRecord.create(manual_id: temp_manual_id, slug: temp_slug)
      ManualRecord.create(slug: temp_slug)
      expect {
        subject.new_manual
      }.to raise_error(RuntimeError,  "More than one manual found for slug '#{temp_slug}'")
    end
  end

  describe "#move!" do
    let!(:existing_manual) { ManualRecord.create(manual_id: existing_manual_id, slug: existing_slug) }
    let!(:temp_manual) { ManualRecord.create(manual_id: temp_manual_id, slug: temp_slug) }
    let!(:existing_section_1) { FactoryGirl.create(:specialist_document_edition, slug: "#{existing_slug}/existing_section_1", document_id: "12345") }
    let!(:existing_section_2) { FactoryGirl.create(:specialist_document_edition, slug: "#{existing_slug}/existing_section_2", document_id: "23456") }
    let!(:temporary_section_1) { FactoryGirl.create(:specialist_document_edition, slug: "#{temp_slug}/temp_section_1", document_id: "abcdef") }
    let!(:temporary_section_2) { FactoryGirl.create(:specialist_document_edition, slug: "#{temp_slug}/temp_section_2", document_id: "bcdefg") }

    let!(:existing_section_3) { FactoryGirl.create(:specialist_document_edition, slug: "#{existing_slug}/section_3", document_id: "34567") }
    let!(:temporary_section_3) { FactoryGirl.create(:specialist_document_edition, slug: "#{temp_slug}/section_3", document_id: "cdefgh") }

    let!(:existing_publication_log) { FactoryGirl.create(:publication_log, slug: "#{existing_slug}/slug-for-existing-section", change_note: "Hello from #{existing_manual_id}") }
    let!(:temporary_publication_log) { FactoryGirl.create(:publication_log, slug: "#{temp_slug}/slug-for-temp-section", change_note: "Hello from #{temp_manual_id}") }

    before do
      allow(STDOUT).to receive(:puts)
      existing_manual.editions << ManualRecord::Edition.new(document_ids: %w(12345 23456 34567))
      temp_manual.editions << ManualRecord::Edition.new(document_ids: %w(abcdef bcdefg cdefgh))
      stub_any_publishing_api_unpublish
      subject.move!
    end

    it "destroys the existing manual" do
      expect {
        existing_manual.reload
      }.to raise_error(Mongoid::Errors::DocumentNotFound)
    end

    it "moves the temporary manual to the existing slug" do
      expect(temp_manual.reload.slug).to eq(existing_slug)
      expect(ManualRecord.where(slug: temp_slug).count).to be(0)
    end

    it "unpublishes the temporary manual with a redirect to the existing slug" do
      assert_publishing_api_unpublish(temp_manual_id,
                                      type: "redirect",
                                      alternative_path: "/#{existing_slug}",
                                      discard_drafts: true)
    end

    it "unpublishes the existing manual with a gone" do
      assert_publishing_api_unpublish(existing_manual_id,
                                      type: "gone",
                                      discard_drafts: true)
    end

    it "unpublishes the existing manual's sections with redirects to the existing slug" do
      assert_publishing_api_unpublish(existing_section_1.document_id,
                                      type: "redirect",
                                      alternative_path: "/#{existing_slug}",
                                      discard_drafts: true)

      assert_publishing_api_unpublish(existing_section_2.document_id,
                                      type: "redirect",
                                      alternative_path: "/#{existing_slug}",
                                      discard_drafts: true)
    end

    it "issues a gone for existing manual's sections that would be reused one of the new manual's sections" do
      assert_publishing_api_unpublish(existing_section_3.document_id,
                                      type: "gone",
                                      discard_drafts: true)
    end

    it "destroys the existing manual's sections" do
      expect {
        existing_section_1.reload
      }.to raise_error(Mongoid::Errors::DocumentNotFound)

      expect {
        existing_section_2.reload
      }.to raise_error(Mongoid::Errors::DocumentNotFound)

      expect {
        existing_section_3.reload
      }.to raise_error(Mongoid::Errors::DocumentNotFound)
    end

    it "moves the temporary manual's sections to the existing slug" do
      expect(temporary_section_1.reload.slug).to eq("#{existing_slug}/temp_section_1")
      expect(temporary_section_2.reload.slug).to eq("#{existing_slug}/temp_section_2")
      expect(temporary_section_3.reload.slug).to eq("#{existing_slug}/section_3")
      expect(SpecialistDocumentEdition.where(slug: /#{temp_slug}/).count).to be(0)
    end

    it "unpublishes the temporary manual's section slugs with redirects to their existing slug version" do
      assert_publishing_api_unpublish(temporary_section_1.document_id,
                                      type: "redirect",
                                      alternative_path: "/#{existing_slug}/temp_section_1",
                                      discard_drafts: true)

      assert_publishing_api_unpublish(temporary_section_2.document_id,
                                      type: "redirect",
                                      alternative_path: "/#{existing_slug}/temp_section_2",
                                      discard_drafts: true)

      assert_publishing_api_unpublish(temporary_section_3.document_id,
                                      type: "redirect",
                                      alternative_path: "/#{existing_slug}/section_3",
                                      discard_drafts: true)
    end

    it "removes the publication logs for the existing manual" do
      expect { existing_publication_log.reload }.to raise_error(Mongoid::Errors::DocumentNotFound)
    end
  end
end
