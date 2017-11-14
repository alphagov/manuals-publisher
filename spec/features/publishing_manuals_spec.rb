require "spec_helper"
require "sidekiq/testing"

RSpec.describe "Publishing manuals", type: :feature do
  before do
    Sidekiq::Testing.inline!
    login_as(:generic_editor)
    stub_organisation_details(GDS::SSO.test_user.organisation_slug)
  end

  let(:manual_fields) { { title: "Example manual title", summary: "A summary" } }

  describe "publishing a manual with major and minor updates" do
    let(:publish_time) { DateTime.now }

    before do
      manual = create_manual_without_ui(manual_fields)

      @sections = [].tap do |sections|
        sections << create_section_without_ui(manual, title: "Section 1 major", summary: "Section 1 summary", body: "Section body")
        sections << create_section_without_ui(manual, title: "Section 1", summary: "Section 1 minor summary", body: "Section body minor update", minor_update: true)
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

  # https://trello.com/c/OmstjgzY/30-investigate-manuals-publisher-bug-which-prevented-publish
  # There's a problem with draft sections which have not been previously published.
  # On removing a section the draft is discarded in the Publishing API and the
  # section is added to Manual#removed_sections, the publishing adapter then tries
  # to unpublish these removed sections. This results in a GdsApi::HTTPNotFound exception
  # from the Publishing API as the section does not exist there.
  describe "publishing a manual after a section which has never been published is removed" do
    before do
      @manual = create_manual_without_ui(manual_fields)
      create_section_without_ui(@manual, title: "First Section", summary: "First Section", body: "## First Section")

      go_to_manual_page(@manual.title)
      publish_manual

      click_on "Add section"

      fill_in("Section title", with: "Second Section")
      fill_in("summary", with: "Second Section")
      fill_in("body", with: "## Second Section")

      save_as_draft

      withdraw_section(@manual.title, "Second Section")

      # Reload Manual to get up-to-date sections
      @manual = Manual.find(@manual.id, User.gds_editor)
    end

    it "doesn't attempt to unpublish the section" do
      uuid = @manual.removed_sections.find { |s| s.title == "Second Section" }.uuid
      expect(Services.publishing_api).not_to receive(:unpublish)
        .with(uuid,
              type: "redirect",
              alternative_path: "/#{@manual.slug}",
              discard_drafts: true)

      go_to_manual_page(@manual.title)
      publish_manual
    end
  end

  describe "publishing a manual after a section which has been published is removed" do
    before do
      @manual = create_manual_without_ui(manual_fields)
      create_section_without_ui(@manual, title: "First Section", summary: "First Section", body: "## First Section")
      create_section_without_ui(@manual, title: "Second Section", summary: "Second Section", body: "## Second Section")

      go_to_manual_page(@manual.title)

      publish_manual

      withdraw_section(@manual.title, "Second Section")

      @manual = Manual.find(@manual.id, User.gds_editor)
    end

    it "unpublishes the section" do
      uuid = @manual.removed_sections.find { |s| s.title == "Second Section" }.uuid
      expect(Services.publishing_api).to receive(:unpublish)
        .with(uuid,
              type: "redirect",
              alternative_path: "/#{@manual.slug}",
              discard_drafts: true)

      publish_manual
    end
  end
end
