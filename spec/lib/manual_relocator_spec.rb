require "spec_helper"
require "manual_relocator"

describe ManualRelocator do
  include GdsApi::TestHelpers::PublishingApiV2

  describe ".move" do
    let(:existing_manual_id) { SecureRandom.uuid }
    let(:temp_manual_id) { SecureRandom.uuid }
    let(:existing_slug) { "guidance/real-slug" }
    let(:temp_slug) { "guidance/temporary-slug" }
    let!(:existing_manual) { ManualRecord.create(manual_id: existing_manual_id, slug: existing_slug) }
    let!(:temp_manual) { ManualRecord.create(manual_id: temp_manual_id, slug: temp_slug) }
    let!(:existing_section_1) { FactoryGirl.create(:specialist_document_edition, document_id: "12345") }
    let!(:existing_section_2) { FactoryGirl.create(:specialist_document_edition, document_id: "23456") }
    let!(:temporary_section_1) { FactoryGirl.create(:specialist_document_edition, document_id: "abcdef") }
    let!(:temporary_section_2) { FactoryGirl.create(:specialist_document_edition, document_id: "bcdefg") }

    before do
      allow(STDOUT).to receive(:puts)
      existing_manual.editions << ManualRecord::Edition.new(document_ids: %w(12345 23456))
      temp_manual.editions << ManualRecord::Edition.new(document_ids: %w(abcdef bcdefg))
      stub_any_publishing_api_unpublish
      ManualRelocator.move(temp_slug, existing_slug)
    end

    it "moves a manual from one slug to another" do
      expect(temp_manual.reload.slug).to eq(existing_slug)
      expect(ManualRecord.where(slug: temp_slug).count).to be(0)
    end

    it "unpublishes the temporary manual" do
      assert_publishing_api_unpublish(temp_manual_id,
                                      type: "redirect",
                                      alternative_path: "/#{existing_slug}",
                                      discard_drafts: true)
    end

    it "redirects existing manual section paths" do
      assert_publishing_api_unpublish(existing_section_1.document_id,
                                      type: "redirect",
                                      alternative_path: "/#{existing_slug}",
                                      discard_drafts: true)

      assert_publishing_api_unpublish(existing_section_2.document_id,
                                      type: "redirect",
                                      alternative_path: "/#{existing_slug}",
                                      discard_drafts: true)
    end

    it "redirects temporary manual section paths" do
      assert_publishing_api_unpublish(temporary_section_1.document_id,
                                      type: "redirect",
                                      alternative_path: "/#{existing_slug}",
                                      discard_drafts: true)

      assert_publishing_api_unpublish(temporary_section_2.document_id,
                                      type: "redirect",
                                      alternative_path: "/#{existing_slug}",
                                      discard_drafts: true)

    end
  end
end
