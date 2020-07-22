require "adapters"

class Manual::RepublishService
  def initialize(user:, manual_id:)
    @user = user
    @manual_id = manual_id
  end

  def call
    manual_versions = Manual.find(manual_id, user).current_versions

    published_manual_version = manual_versions[:published]
    draft_manual_version = manual_versions[:draft]

    if published_manual_version.present?
      Adapters.publishing.save_draft(published_manual_version, republish: true)
      Adapters.publishing.publish(published_manual_version, republish: true)
    end

    if draft_manual_version.present?
      Adapters.publishing.save_draft(draft_manual_version, republish: true)
    end

    manual_versions
  end

private

  attr_reader :user, :manual_id
end
