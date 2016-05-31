require "spec_helper"
require "sidekiq/testing"
Sidekiq::Testing.inline!

RSpec.describe "Republishing documents", type: :feature do
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
      update_type: "republish",
      locale: "en",
      public_updated_at: "2016-05-11T10:56:07+00:00",
      details: {"metadata" => {"opened_date" => "2013-04-20", # These nested hashes use Strings as keys because Symbols gives a false negative in the request_json_matching matcher.
                               "market_sector" => "some-market-sector",
                               "case_type" => "a-case-type",
                               "case_state" => "open",
                               "document_type" => @document.document_type},
                "change_history" => [],
                "body" => [{"content_type" => "text/html",
                            "content" => "<p>My body</p>\n"},
                           {"content_type" => "text/govspeak",
                            "content" => "My body"}],
                "max_cache_time" => 10,
      },
      routes: [{"path" => "/" + @document.slug,
                "type" => "exact"}],
      links: {
        "organisations" => ["38eb5d8f-2d89-480c-8655-e2e7ac23f8f4"]
      }
    }
  end

  let(:rummager_fields) do
    {
      title: @document.title,
      description: @document.summary,
      link: "/" + @document.slug,
      indexable_content: @document.body,
      organisations: ["air-accidents-investigation-branch"],
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

    it "should push to Publishing API as content" do
      SpecialistPublisher.document_services("aaib_report").republish_all.call
      assert_publishing_api_put_item("/c/d", request_json_matching(publishing_api_fields))
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
