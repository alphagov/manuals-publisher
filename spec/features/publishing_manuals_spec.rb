require "spec_helper"
require "govuk_sidekiq/testing"

RSpec.describe "Publishing manuals", type: :feature do
  before do
    Sidekiq::Testing.inline!
    login_as(:generic_editor)
    stub_organisation_details(GDS::SSO.test_user.organisation_slug)
  end

  let(:manual_fields) { { title: "Example manual title", summary: "A summary" } }

  describe "publishing a manual with major and minor updates" do
    let(:publish_time) { Time.zone.now }

    before do
      manual = create_manual_without_ui(manual_fields)

      @sections = [].tap do |sections|
        sections << create_section_without_ui(manual, { title: "Section 1 major", summary: "Section 1 summary", body: "Section body" })
        sections << create_section_without_ui(manual, { title: "Section 1", summary: "Section 1 minor summary", body: "Section body minor update", minor_update: true })
      end

      # Re-fetch manual to include sections
      @manual = Manual.find(manual.id, User.gds_editor)

      Timecop.freeze(publish_time) do
        publish_manual_without_ui(@manual)
      end

      check_manual_is_drafted_to_publishing_api(@manual.id, number_of_drafts: 4)
    end

    it "drafts the manual and sections and publishes them to the Publishing API" do
      @sections.each do |section|
        check_section_is_drafted_to_publishing_api(section.uuid, number_of_drafts: 2)
        check_manual_and_sections_were_published(@manual, section, manual_fields, section_fields(section))
      end
    end

    it "creates publication logs for major updates to sections only" do
      expect(PublicationLog.count).to eq 1
      expect(PublicationLog.first.title).to eq "Section 1 major"
    end

    it "sets the exported_at timestamp on the section" do
      expect(@sections.first.reload.exported_at).to be_within(1.second).of publish_time
    end
  end
end
