require "spec_helper"
require "sidekiq/testing"

RSpec.describe "Republishing documents", type: :feature do
  context "for drafts" do
    before do
      create(:specialist_document_edition,
        document_type: "aaib_report",
        state: "draft",
        slug: "a/b",
      )
    end

    it "should NOT push to Publishing API" do
      SpecialistPublisher.document_services("aaib_report").republish_all.call

      assert_publishing_api_put_item("/a/b", {}, 0)
      assert_publishing_api_put_draft_item("/a/b", {}, 0)
      expect(fake_rummager).not_to have_received(:add_document)
    end
  end

  context "for published documents" do
    before do
      @document = create(:specialist_document_edition,
        document_type: "aaib_report",
        state: "published",
        slug: "c/d",
      )
    end

    it "should push to Publishing API as content" do
      SpecialistPublisher.document_services("aaib_report").republish_all.call

      rummager_fields = {title: @document.title,
       description: @document.summary,
       link: "/" + @document.slug,
       indexable_content: @document.body,
       organisations: ["air-accidents-investigation-branch"]}

      assert_publishing_api_put_item("/c/d")
      expect(fake_rummager).to have_received(:add_document)
                                 .with(@document.document_type, "/c/d", hash_including(rummager_fields))
    end
  end

  context "for withdrawn documents" do
    before do
      create(:specialist_document_edition,
             document_type: "aaib_report",
             state: "archived",
             slug: "e/f",
      )
    end

    it "should NOT push to Publishing API" do
      SpecialistPublisher.document_services("aaib_report").republish_all.call

      assert_publishing_api_put_item("/e/f", {}, 0)
      assert_publishing_api_put_draft_item("/e/f", {}, 0)
      expect(fake_rummager).not_to have_received(:add_document)
    end

  end
end
