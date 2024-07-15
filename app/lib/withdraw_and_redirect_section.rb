class WithdrawAndRedirectSection
  def initialize(user:, manual_path:, section_path:, redirect:, discard_draft:, dry_run: false)
    @user = user
    @manual_path = manual_path
    @section_path = section_path
    @redirect = redirect
    @discard_draft = discard_draft
    @dry_run = dry_run
  end

  def execute
    section_uuid = SectionEdition.find_by(slug: section_path, state: "published").section_uuid
    manual = Manual.find_by_slug!(manual_path, user)

    return if dry_run

    section = Section.find(manual, section_uuid)

    Adapters.publishing.unpublish_section(section, redirect:, discard_drafts: discard_draft)
  end

private

  attr_reader :user, :manual_path, :section_path, :redirect, :discard_draft, :dry_run

  class SectionNotPublishedError < StandardError; end
end
