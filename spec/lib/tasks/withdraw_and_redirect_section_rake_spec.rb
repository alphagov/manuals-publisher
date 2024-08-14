require "gds_api/test_helpers/publishing_api"
require "rake"

describe "withdraw and redirect section rake tasks", type: :rake_task do
  include GdsApi::TestHelpers::PublishingApi

  before do
    Rake.application.clear
    load "lib/tasks/withdraw_and_redirect_section.rake"
    Rake::Task.define_task(:environment)
    stub_any_publishing_api_call
  end

  describe "bulk_redirect_section_to_manual" do
    let(:task) { Rake::Task["bulk_redirect_section_to_manual"] }

    it "redirect sections that exist and output an error line for ones that don't" do
      FactoryBot.create(:manual_record, slug: "guidance/parent_path", state: "withdrawn")
      FactoryBot.create(:section_edition, section_uuid: "1234", slug: "guidance/parent_path/existing_doc", state: "published")
      allow(SecureRandom).to receive(:uuid).and_return("some-random-uuid")

      expect { task.invoke("./spec/fixtures/bulk_test.csv") }.to output(/unable to redirect guidance\/parent_path\/non_existing_doc/).to_stdout

      assert_publishing_api_put_content(
        "some-random-uuid",
        document_type: "redirect",
        schema_name: "redirect",
        publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
        base_path: "/guidance/parent_path/existing_doc",
        redirects: [
          {
            path: "/guidance/parent_path/existing_doc",
            type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
            destination: "/guidance/parent_path",
          },
        ],
        update_type: "major",
      )
      assert_publishing_api_publish("some-random-uuid")
    end
  end
end
