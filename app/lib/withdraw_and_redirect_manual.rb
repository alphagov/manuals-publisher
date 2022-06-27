require "adapters"

class WithdrawAndRedirectManual
  def initialize(user:, manual_path:, redirect:, include_sections:, discard_drafts:)
    @user = user
    @manual_path = manual_path
    @redirect = redirect
    @include_sections = include_sections
    @discard_drafts = discard_drafts
  end

  def execute
    manual = Manual.find_by_slug!(manual_path, user)

    published_manual = manual.current_versions[:published]

    raise ManualNotPublishedError, manual.slug if published_manual.blank?

    published_manual.withdraw
    published_manual.save!(user)

    Adapters.publishing.unpublish_and_redirect_manual_and_sections(
      published_manual,
      redirect: redirect,
      include_sections: include_sections,
      discard_drafts: discard_drafts,
    )
  end

private

  attr_reader :user, :manual_path, :redirect, :include_sections, :discard_drafts

  class ManualNotPublishedError < StandardError; end
end
