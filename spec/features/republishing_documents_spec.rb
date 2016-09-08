require "spec_helper"
require "gds_api/test_helpers/publishing_api_v2"
require "sidekiq/testing"
Sidekiq::Testing.inline!

RSpec.describe "Republishing documents", type: :feature do
  include GdsApi::TestHelpers::PublishingApiV2

  let(:public_timestamp) { "2016-05-11 10:56:07" }
  let(:publishing_api_fields) do
    {
      content_id: @document.document_id,
      schema_name: "specialist_document",
      document_type: @document.document_type,
      publishing_app: "specialist-publisher",
      rendering_app: "specialist-frontend",
      title: @document.title,
      description: @document.summary,
      update_type: "major",
      locale: "en",
      public_updated_at: "2016-05-11T10:56:07+00:00",
      last_edited_at: "2016-05-11T10:56:07+00:00",
      routes: [{"path" => "/" + @document.slug, "type" => "exact"}],
      links: { "organisations" => ["38eb5d8f-2d89-480c-8655-e2e7ac23f8f4"] },
      details: {
        "metadata" => {
          "opened_date" => "2013-04-20", # These nested hashes use Strings as keys because Symbols gives a false negative in the request_json_matching matcher.
          "market_sector" => "some-market-sector",
          "case_type" => "a-case-type",
          "case_state" => "open",
        },
        "change_history" => [],
        "body" => [
          {"content_type" => "text/html", "content" => "<p>My body</p>\n"},
          {"content_type" => "text/govspeak", "content" => "My body"}
        ],
        "max_cache_time" => 10,
        "temporary_update_type" => false,
      },
    }
  end

  let(:rummager_fields) do
    {
      title: @document.title,
      description: @document.summary,
      link: "/" + @document.slug,
      indexable_content: @document.body,
      public_timestamp: public_timestamp,
      aircraft_category: nil,
      report_type: nil,
      date_of_occurrence: nil,
      location: nil,
      aircraft_type: nil,
      registration: nil
    }
  end

  before do
    Timecop.freeze(public_timestamp)
  end

  after do
    Timecop.return
    Sidekiq::Worker.clear_all
  end

  context "for drafts" do
    before do
      @document = create(:specialist_document_edition,
        document_type: "aaib_report",
        state: "draft",
        slug: "a/b",
      )

      create(:specialist_document_edition,
             document_id: "document_id_2",
             document_type: "aaib_report",
             state: "draft",
             slug: "a/bc",
      )
    end

    it "should push to Publishing API as draft-content" do
      SpecialistPublisher.document_services("aaib_report").republish_all.call

      assert_publishing_api_put_item("/a/b", {}, 0)
      assert_publishing_api_put_draft_item("/a/b", request_json_matching(publishing_api_fields))
      expect(fake_rummager).not_to have_received(:add_document)
                                 .with(@document.document_type, "/a/b", hash_including(rummager_fields))
    end

    it "should send updated_at as last_edited_at timestamp" do
      SpecialistPublisher.document_services("aaib_report").republish_all.call
      assert_publishing_api_put_draft_item("/a/b", request_json_matching(last_edited_at: "2016-05-11T10:56:07+00:00"))
    end

    it "should add job to worker queue when republishing all documents" do
      Sidekiq::Testing.fake! do
        expect {
          SpecialistPublisher.document_services("aaib_report").republish_all.call
        }.to change(RepublishDocumentWorker.jobs, :size).by(2)
      end
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

    it "should push to Publishing API as content with a 'republish' update_type" do
      SpecialistPublisher.document_services("aaib_report").republish_all.call
      publishing_api_fields[:update_type] = "republish"
      assert_publishing_api_put_item("/c/d", request_json_matching(publishing_api_fields))
      expect(fake_rummager).to have_received(:add_document)
                                 .with(@document.document_type, "/c/d", hash_including(rummager_fields))
    end

    it "should send updated_at as last_edited_at timestamp" do
      SpecialistPublisher.document_services("aaib_report").republish_all.call
      assert_publishing_api_put_item("/c/d", request_json_matching(last_edited_at: "2016-05-11T10:56:07+00:00"))
    end
  end

  context "for withdrawn documents" do
    before do
      create(:specialist_document_edition,
             document_type: "aaib_report",
             state: "archived",
             slug: "e/f",
             document_id: "some-content-id",
      )
    end

    it "should unpublish using the allow_draft flag" do
      stub_any_publishing_api_call

      SpecialistPublisher.document_services("aaib_report").republish_all.call

      assert_publishing_api_put_item("/e/f", {}, 0)
      assert_publishing_api_put_draft_item("/e/f", {}, 1)

      assert_publishing_api_unpublish(
        "some-content-id", { "type" => "gone", "allow_draft" => true }
      )

      expect(fake_rummager).not_to have_received(:add_document)
    end
  end

  context "for published documents with new draft" do
    before do
      slug_generator = double(:slug_generator)
      latest_draft_doc = create(
          :specialist_document_edition,
          document_id: "document_id_2",
          document_type: "aaib_report",
          state: "draft",
          slug: "g/draft")
      edition_doc = create(
          :specialist_document_edition,
          document_id: "document_id_1",
          document_type: "aaib_report",
          state: "published",
          slug: "g/published")
      @document = build(:specialist_document,
                         slug_generator: slug_generator,
                         id: 123,
                         editions: [edition_doc, latest_draft_doc])
    end

    it "should get state for frontend" do
      expect(@document.draft?).to eq(true)
      expect(@document.withdrawn?).to eq(false)
      expect(@document.published?).to eq(true)
      expect(ApplicationHelper.state_for_frontend(@document).first).to eq("published with new draft")
    end

    it "should push to Publishing API as content" do
      SpecialistPublisher.document_services("aaib_report").republish_all.call

      assert_publishing_api_put_item("/g/published", { update_type: "republish" }, 1)
      assert_publishing_api_put_draft_item("/g/draft", { update_type: "major" }, 1)

      assert_publishing_api_put_item("/g/draft", {}, 0)
      assert_publishing_api_put_draft_item("/g/published", {}, 0)

      expect(fake_rummager).to have_received(:add_document)
    end
  end

  context "for withdrawn documents with new draft" do
    before do
      slug_generator = double(:slug_generator)
      latest_draft_doc = create(:specialist_document_edition,
                                document_id: "document_id_2",
                                document_type: "aaib_report",
                                state: "draft",
                                slug: "i/j/draft")
      edition_doc = create(:specialist_document_edition,
                           document_id: "document_id_1",
                           document_type: "aaib_report",
                           state: "archived",
                           slug: "i/j/archived")
      @document = build(:specialist_document,
                        slug_generator: slug_generator,
                        id: 123,
                        editions: [edition_doc, latest_draft_doc])
    end

    it "should get state for frontend" do
      expect(@document.draft?).to eq(true)
      expect(@document.withdrawn?).to eq(true)
      expect(@document.published?).to eq(false)
      expect(ApplicationHelper.state_for_frontend(@document).first).to eq("withdrawn with new draft")
    end

    it "should push to Publishing API and then unpublish the draft" do
      stub_any_publishing_api_call

      SpecialistPublisher.document_services("aaib_report").republish_all.call

      assert_publishing_api_put_item("/i/j", {}, 0)

      assert_publishing_api_put_draft_item("/i/j/archived", {}, 1)
      assert_publishing_api_unpublish(
        "document_id_1", { "type" => "gone", "allow_draft" => true }
      )

      assert_publishing_api_put_draft_item("/i/j/draft", {}, 1)

      expect(fake_rummager).not_to have_received(:add_document)
    end
  end
end
