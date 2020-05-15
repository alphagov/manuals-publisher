require "spec_helper"
require "govuk_sidekiq/testing"

RSpec.describe "Republishing manuals", type: :feature do
  before do
    Sidekiq::Testing.inline!
    login_as(:generic_editor)
    stub_organisation_details(GDS::SSO.test_user.organisation_slug)
  end

  let(:original_publish_time) { Time.zone.now - 1.day }
  let(:manual_fields) { { title: "Example manual title", summary: "A summary" } }
  let(:edited_manual_fields) { { title: "Editted manual title", summary: "A changed summary" } }

  def edited_section_fields(section)
    {
      title: "I've changed this section: #{section.title}",
      summary: "And its summary: #{section.summary}",
    }
  end

  def create_manual_with_sections(published: true)
    manual = create_manual_without_ui(manual_fields)
    @sections = create_sections_for_manual_without_ui(manual: manual, count: 2)

    # Re-fetch manual to include sections
    @manual = Manual.find(manual.id, User.gds_editor)

    if published
      Timecop.freeze(original_publish_time) do
        publish_manual_without_ui(@manual)
      end
    end

    if published
      check_manual_is_drafted_to_publishing_api(@manual.id, number_of_drafts: 4)
      check_manual_is_published_to_publishing_api(@manual.id)
    else
      check_manual_is_drafted_to_publishing_api(@manual.id, number_of_drafts: 3)
    end

    WebMock::RequestRegistry.instance.reset!
  end

  def edit_manual_and_sections
    @edited_manual = edit_manual_without_ui(@manual, edited_manual_fields)

    @edited_sections = @sections.map do |section|
      edit_section_without_ui(@manual, section, edited_section_fields(section))
    end

    WebMock::RequestRegistry.instance.reset!
  end

  describe "republishing a published manual with sections" do
    before do
      create_manual_with_sections(published: true)

      republish_manuals_without_ui
    end

    it "sends the manual and the sections to the Publishing API" do
      check_manual_is_drafted_to_publishing_api(
        @manual.id,
        extra_attributes: {
          title: manual_fields[:title],
          description: manual_fields[:summary],
        },
      )
      check_manual_is_published_to_publishing_api(@manual.id)
      @sections.each do |section|
        check_section_is_drafted_to_publishing_api(
          section.uuid,
          extra_attributes: {
            title: section.title,
            description: section.summary,
          },
        )
        check_section_is_published_to_publishing_api(section.uuid)
      end
    end

    it "does not change the exported timestamp" do
      expect(@sections.first.reload.exported_at).to be_within(1.second).of original_publish_time
    end
  end

  describe "republishing a draft manual with sections" do
    before do
      create_manual_with_sections(published: false)

      republish_manuals_without_ui
    end

    it "sends the manual and the sections to the Publishing API" do
      check_manual_is_drafted_to_publishing_api(
        @manual.id,
        extra_attributes: {
          title: manual_fields[:title],
          description: manual_fields[:summary],
        },
      )
      check_manual_is_not_published_to_publishing_api(@manual.id)
      @sections.each do |section|
        check_section_is_drafted_to_publishing_api(
          section.uuid,
          extra_attributes: {
            title: section.title,
            description: section.summary,
          },
        )
        check_section_is_not_published_to_publishing_api(section.uuid)
      end
    end

    it "does not change the exported timestamp" do
      expect(@sections.first.reload.exported_at).to be_nil
    end
  end

  describe "republishing a published manual with sections and a new draft waiting" do
    before do
      create_manual_with_sections(published: true)

      @edited_section = edit_manual_and_sections

      republish_manuals_without_ui
    end

    it "sends the published versions of the manual and its sections to the Publishing API" do
      check_manual_is_drafted_to_publishing_api(
        @manual.id,
        extra_attributes: {
          title: manual_fields[:title],
          description: manual_fields[:summary],
        },
      )
      check_manual_is_published_to_publishing_api(@manual.id)
      @sections.each do |section|
        edited_fields = edited_section_fields(section)
        check_section_is_drafted_to_publishing_api(
          section.uuid,
          extra_attributes: {
            title: edited_fields[:title],
            description: edited_fields[:summary],
          },
        )
        check_section_is_published_to_publishing_api(section.uuid)
      end
    end

    it "sends the draft versions of the manual and its sections to the Publishing API" do
      check_manual_is_drafted_to_publishing_api(
        @manual.id,
        extra_attributes: {
          title: edited_manual_fields[:title],
          description: edited_manual_fields[:summary],
        },
      )
      # we can't check that it's not published (because one version will be)
      # all we can check is that it was only published once
      check_manual_is_published_to_publishing_api(@manual.id, times: 1)
      @edited_sections.each do |section|
        check_section_is_drafted_to_publishing_api(
          section.uuid,
          extra_attributes: {
            title: section.title,
            description: section.summary,
          },
        )
        # we can't check that it's not published (because one version will be)
        # all we can check is that it was only published once
        check_section_is_published_to_publishing_api(section.uuid, times: 1)
      end
    end

    it "does not set the exported timestamp of the draft version of the section" do
      expect(@edited_sections.first.reload.exported_at).to be_nil
    end

    it "does not set the exported timestamp of the previously published version of the section" do
      expect(@sections.first.reload.exported_at).to be_within(1.second).of original_publish_time
    end
  end
end
