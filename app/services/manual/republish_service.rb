class Manual::RepublishService
  def self.call(user:, manual_id:)
    manual_versions = Manual.find(manual_id, user).current_versions

    published_manual_version = manual_versions[:published]
    draft_manual_version = manual_versions[:draft]

    if published_manual_version.present?
      PublishingAdapter.save_draft(published_manual_version, republish: true)
      PublishingAdapter.publish(published_manual_version, republish: true)
    end

    if draft_manual_version.present?
      PublishingAdapter.save_draft(draft_manual_version, republish: true)
    end

    manual_versions
  end
end
