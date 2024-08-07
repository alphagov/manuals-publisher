class WithdrawAndRedirectSection
  def initialize(user:, section_path:, redirect:, discard_draft:, dry_run: false)
    @user = user
    @section_path = section_path
    @redirect = redirect
    @discard_draft = discard_draft
    @dry_run = dry_run
  end

  def execute
    section_uuid = SectionEdition.find_by(slug: section_path, state: "published").section_uuid

    return if dry_run

    section = Section.find(section_uuid)

    if discard_draft && section.draft?
      Publishing::UnpublishAdapter.unpublish_and_redirect_section(section, redirect:, discard_drafts: true)
    else
      Publishing::UnpublishAdapter.unpublish_and_redirect_section(section, redirect:, discard_drafts: false)
    end
  end

private

  attr_reader :user, :section_path, :redirect, :discard_draft, :dry_run
end
