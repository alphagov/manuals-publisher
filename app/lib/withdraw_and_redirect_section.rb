class WithdrawAndRedirectSection
  def initialize(user:, section_path:, redirect:, discard_draft:, dry_run: false)
    @user = user
    @section_path = section_path
    @redirect = redirect
    @discard_draft = discard_draft
    @dry_run = dry_run
  end

  def execute
    section_uuids = SectionEdition.where(slug: section_path, state: "published").pluck(:section_uuid).uniq
    raise SectionNotPublishedError if section_uuids.empty?
    raise SlugsWithMultiplePublishedSectionUUIDError if section_uuids.count > 1

    section = Section.find(section_uuids.first)

    return if dry_run

    discard_drafts = discard_draft && section.draft?
    Publishing::UnpublishAdapter.unpublish_and_redirect_section(section, redirect:, discard_drafts:)
  end

private

  attr_reader :user, :section_path, :redirect, :discard_draft, :dry_run

  class SlugsWithMultiplePublishedSectionUUIDError < StandardError
    def message
      "The slug lookup returned multiple published editions with different Section UUIDs. Please handle separately for the Section UUID you want to archive."
    end
  end

  class SectionNotPublishedError < StandardError
    def message
      "Unable to find a published Section Edition for this slug."
    end
  end
end
