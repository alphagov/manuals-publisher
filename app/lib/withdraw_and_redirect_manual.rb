class WithdrawAndRedirectManual
  def initialize(user:, manual_path:, redirect:, include_sections:, discard_drafts:, dry_run: false)
    @user = user
    @manual_path = manual_path
    @redirect = redirect
    @include_sections = include_sections
    @discard_drafts = discard_drafts
    @dry_run = dry_run
  end

  def execute
    manual = Manual.find_by_slug!(manual_path, user)

    return if dry_run

    published_manual = manual.current_versions[:published]

    raise ManualNotPublishedError, manual.slug if published_manual.blank?

    published_manual.withdraw
    published_manual.save!(user)

    Adapters.publishing.unpublish_and_redirect_manual_and_sections(
      published_manual,
      redirect:,
      include_sections:,
      discard_drafts:,
    )
  end

private

  attr_reader :user, :manual_path, :redirect, :include_sections, :discard_drafts, :dry_run

  class ManualNotPublishedError < StandardError; end
end
