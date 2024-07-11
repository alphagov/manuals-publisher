require "spec_helper"
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

  describe "bulk withdraw sections" do
    let(:task) { Rake::Task["bulk_withdraw_and_redirect_section_to_manual"] }

    it "withdraws sections that exist and output an error line for ones that don't" do
      FactoryBot.create(:manual_record, slug: "guidance/parent_path", state: "withdrawn")
      FactoryBot.create(:section_edition, section_uuid: "1234", slug: "guidance/parent_path/existing_doc", state: "published")

      expect { task.invoke("./spec/fixtures/bulk_test.csv") }.to output(/unable to withdraw guidance\/parent_path\/non_existing_doc/).to_stdout

      assert_publishing_api_unpublish(
        "1234",
        type: "redirect",
        alternative_path: "/guidance/parent_path",
      )
    end
  end
end
