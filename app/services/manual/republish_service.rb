require "adapters"

class Manual::RepublishService
  def initialize(user:, manual_id:)
    @user = user
    @manual_id = manual_id
  end

  def call
    if published_manual_version.present?
      export_published_manual_via_publishing_api
      republish_published_manual_to_publishing_api
      add_published_manual_to_search_index
    end

    if draft_manual_version.present?
      export_draft_manual_via_publishing_api
    end

    manual_versions
  end

private

  attr_reader :user, :manual_id

  def published_manual_version
    manual_versions[:published]
  end

  def draft_manual_version
    manual_versions[:draft]
  end

  def export_published_manual_via_publishing_api
    Adapters.publishing.save(published_manual_version, republish: true)
  end

  def republish_published_manual_to_publishing_api
    Adapters.publishing.publish(published_manual_version, republish: true)
  end

  def add_published_manual_to_search_index
    Adapters.search_index.add(published_manual_version)
  end

  def export_draft_manual_via_publishing_api
    Adapters.publishing.save(draft_manual_version, republish: true)
  end

  def manual_versions
    @manual_versions ||= Manual.find(manual_id, user).current_versions
  end
end
