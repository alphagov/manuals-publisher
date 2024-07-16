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
    section_uuid = SectionEdition.find_by(slug: section_path).section_uuid
    manual = Manual.find_by_slug!(manual_path, user)

    return if dry_run

    section = Section.find(manual, section_uuid)

    raise SectionNotPublishedError, section.slug unless section.published?

    if discard_draft && section.draft?
      PublishingAdapter.unpublish_section(section, redirect:, discard_drafts: true)
    else
      PublishingAdapter.unpublish_section(section, redirect:, discard_drafts: false)
    end
  end

private

  attr_reader :user, :manual_path, :section_path, :redirect, :discard_draft, :dry_run

  class SectionNotPublishedError < StandardError; end
end
