require 'spec_helper'

describe AaibReport do

  def aaib_report_content_item(n)
    {
      "content_id" => SecureRandom.uuid,
      "base_path" => "/aaib-reports/example-aaib-report-#{n}",
      "title" => "Example AAIB Report #{n}",
      "description" => "This is the summary of example AAIB Report #{n}",
      "format" => "specialist_document",
      "publishing_app" => "specialist-publisher",
      "rendering_app" => "specialist-frontend",
      "locale" => "en",
      "phase" => "live",
      "public_updated_at" => "2015-11-16T11:53:30",
      "publication_state" => "draft",
      "details" => {
        "body" => "## Header" + ("\r\n\r\nThis is the long body of an example AAIB Report" * 10),
        "metadata" => {
          "date_of_occurrence" => "2015-10-10",
          "document_type" => "aaib_report"
        },
        "change_history" => [],
      },
      "routes" => [
        {
          "path" => "/aaib-reports/example-aaib-report-#{n}",
          "type" => "exact",
        }
      ],
      "redirects" => [],
      "update_type" => "major",
    }
  end

  let(:non_aaib_report_content_item) {
    {
      "content_id" => SecureRandom.uuid,
      "base_path" => "/other-documents/not-an-aaib-report",
      "format" => "specialist_document",
      "details" => {
        "metadata" => {
          "document_type" => "not_an_aaib_report",
        },
      },
    }
  }

  let(:aaib_org_content_item) {
    {
      "base_path" => "/government/organisations/air-accidents-investigation-branch",
      "content_id" => "38eb5d8f-2d89-480c-8655-e2e7ac23f8f4",
      "title" => "Air Accidents Investigation Branch",
      "format" => "placeholder_organisation",
      "need_ids" => [],
      "locale" => "en",
      "updated_at" => "2015-08-20T10:26:56.082Z",
      "public_updated_at" => "2015-04-15T10:04:28.000+00:00",
      "phase" => "live",
      "analytics_identifier" => "OT248",
      "links" => {
        "available_translations" => [
          {
            "content_id" => "38eb5d8f-2d89-480c-8655-e2e7ac23f8f4",
            "title" => "Air Accidents Investigation Branch",
            "base_path" => "/government/organisations/air-accidents-investigation-branch",
            "description" => nil,
            "api_url" => "https://www.gov.uk/api/content/government/organisations/air-accidents-investigation-branch",
            "web_url" => "https://www.gov.uk/government/organisations/air-accidents-investigation-branch",
            "locale" => "en"
          }
        ]
      },
      "description" => nil,
      "details" => {}
    }
  }

  let(:indexable_attributes) {
    {
      "title" => "Example AAIB Report 0",
      "description" => "This is the summary of example AAIB Report 0",
      "link" => "/aaib-reports/example-aaib-report-0",
      "indexable_content" => "## Header" + ("\r\n\r\nThis is the long body of an example AAIB Report" * 10),
      "public_timestamp" => "2015-11-16T11:53:30+00:00",
      "date_of_occurrence" => "2015-10-10",
      "organisations" => ["air-accidents-investigation-branch"],
    }
  }

  before do
    @fields = [
      :base_path,
      :content_id,
    ]

    @aaib_reports = []

    10.times do |n|
      @aaib_reports << aaib_report_content_item(n)
    end

    publishing_api_has_fields_for_format('specialist_document', @aaib_reports, @fields)

    @aaib_reports.each do |aaib_report|
      publishing_api_has_item(aaib_report)
    end

    Timecop.freeze(Time.parse("2015-12-18 10:12:26 UTC"))
  end

  describe "#all" do
    it "returns all AAIB Reports" do
      expect(described_class.all.length).to be(@aaib_reports.length)
    end

    it "rejects any non AAIB Reports" do
      all_specialist_documents = [non_aaib_report_content_item] + @aaib_reports
      publishing_api_has_fields_for_format('specialist_document', all_specialist_documents , @fields)
      publishing_api_has_item(non_aaib_report_content_item)

      expect(described_class.all.length).to be(@aaib_reports.length)
    end
  end

  describe "#find" do
    it "returns a AAIB Report" do
      content_id = @aaib_reports[0]["content_id"]
      aaib_report = described_class.find(content_id)

      expect(aaib_report.base_path).to            eq(@aaib_reports[0]["base_path"])
      expect(aaib_report.title).to                eq(@aaib_reports[0]["title"])
      expect(aaib_report.summary).to              eq(@aaib_reports[0]["description"])
      expect(aaib_report.body).to                 eq(@aaib_reports[0]["details"]["body"])
      expect(aaib_report.date_of_occurrence).to   eq(@aaib_reports[0]["details"]["metadata"]["date_of_occurrence"])
    end
  end

  describe "#save!" do
    it "saves the AAIB Report" do
      stub_any_publishing_api_put_content
      stub_any_publishing_api_put_links

      aaib_report = @aaib_reports[0]

      aaib_report.delete("publication_state")
      aaib_report.merge!("public_updated_at" => "2015-12-18T10:12:26+00:00")
      aaib_report["details"].merge!(
        "change_history" => [
          {
            "public_timestamp" => "2015-12-18T10:12:26+00:00",
            "note" => "First published.",
          }
        ]
      )

      c = described_class.find(aaib_report["content_id"])
      expect(c.save!).to eq(true)

      assert_publishing_api_put_content(c.content_id, request_json_including(aaib_report))
      expect(aaib_report.to_json).to be_valid_against_schema('specialist_document')
    end
  end

  describe "#publish!" do
    it "publishes the AAIB Report" do
      stub_publishing_api_publish(@aaib_reports[0]["content_id"], {})
      stub_any_rummager_post
      publishing_api_has_fields_for_format('organisation', [aaib_org_content_item], [:base_path, :content_id])

      aaib_report = described_class.find(@aaib_reports[0]["content_id"])
      expect(aaib_report.publish!).to eq(true)

      assert_publishing_api_publish(aaib_report.content_id)
      assert_rummager_posted_item(indexable_attributes)
    end
  end
end
