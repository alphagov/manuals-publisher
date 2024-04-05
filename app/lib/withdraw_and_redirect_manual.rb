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

    raise ManualNotPublishedError, manual.slug unless manual.can_withdraw?

    Adapters.publishing.unpublish_and_redirect_manual_and_sections(
      manual,
      redirect:,
      include_sections:,
      discard_drafts:,
    )

    manual.withdraw
    manual.save!(user)
  end

private

  attr_reader :user, :manual_path, :redirect, :include_sections, :discard_drafts, :dry_run

  class ManualNotPublishedError < StandardError; end
end
