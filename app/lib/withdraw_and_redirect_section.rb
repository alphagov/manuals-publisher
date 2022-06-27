require "adapters"

class WithdrawAndRedirectSection
  def initialize(user:, manual_path:, section_path:, redirect:, discard_draft:)
    @user = user
    @manual_path = manual_path
    @section_path = section_path
    @redirect = redirect
    @discard_draft = discard_draft
  end

  def execute
    manual = Manual.find_by_slug!(manual_path, user)
    section_uuid = SectionEdition.find_by(slug: section_path).section_uuid
    section = Section.find(manual, section_uuid)

    raise SectionNotPublishedError, section.slug unless section.published?

    if discard_draft && section.draft?
      Adapters.publishing.unpublish_section(section, redirect: redirect, discard_drafts: true)
    else
      Adapters.publishing.unpublish_section(section, redirect: redirect, discard_drafts: false)
    end
  end

private

  attr_reader :user, :manual_path, :section_path, :redirect, :discard_draft

  class SectionNotPublishedError < StandardError; end
end
