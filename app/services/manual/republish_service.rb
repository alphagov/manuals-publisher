class Manual::RepublishService
  def self.call(user:, manual_id:)
    manual_versions = Manual.find(manual_id, user).current_versions

    published_manual_version = manual_versions[:published]
    draft_manual_version = manual_versions[:draft]

    if published_manual_version.present?
      Publishing::DraftAdapter.save_draft_for_manual_and_sections(published_manual_version, republish: true)
      Publishing::PublishAdapter.publish_manual_and_sections(published_manual_version, republish: true)
    end

    if draft_manual_version.present?
      Publishing::DraftAdapter.save_draft_for_manual_and_sections(draft_manual_version, republish: true)
    end

    manual_versions
  end
end
