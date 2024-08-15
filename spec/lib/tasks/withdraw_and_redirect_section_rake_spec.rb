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

  describe "#withdraw_and_redirect_section" do
    let(:task) { Rake::Task["withdraw_and_redirect_section"] }

    it "withdraws and redirects a given section via slug" do
      manual_record = FactoryBot.create(:manual_record, slug: "guidance/parent_path", state: "withdrawn")
      section_edition = FactoryBot.create(:section_edition, section_uuid: "1234", slug: "guidance/parent_path/existing_doc", state: "published")

      expect { task.invoke(section_edition.slug, manual_record.slug, true) }.to output("Section withdrawn and redirected to #{manual_record.slug}\n").to_stdout

      assert_publishing_api_unpublish(
        section_edition.section_uuid,
        type: "redirect",
        alternative_path: manual_record.slug,
      )
      expect(section_edition.reload.state).to eq "archived"
    end
  end
end
