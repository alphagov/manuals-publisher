class RepublishManualService
  def initialize(manual_id:, context:)
    @manual_id = manual_id
    @context = context
  end

  def call
    if published_manual_version.present?
      export_published_manual_via_publishing_api
      republish_published_manual_to_publishing_api
      republish_published_manual_to_rummager
    end

    if draft_manual_version.present?
      export_draft_manual_via_publishing_api
    end

    manual_versions
  end

private

  attr_reader :manual_id, :context

  def published_manual_version
    manual_versions[:published]
  end

  def draft_manual_version
    manual_versions[:draft]
  end

  def export_published_manual_via_publishing_api
    PublishingApiDraftManualWithSectionsExporter.new.call(published_manual_version, :republish)
  end

  def republish_published_manual_to_publishing_api
    PublishingApiManualWithSectionsPublisher.new.call(published_manual_version, :republish)
  end

  def republish_published_manual_to_rummager
    RummagerManualWithSectionsExporter.new.call(published_manual_version, :republish)
  end

  def export_draft_manual_via_publishing_api
    PublishingApiDraftManualWithSectionsExporter.new.call(draft_manual_version, :republish)
  end

  def manual_versions
    @manual_versions ||= Manual.find(manual_id, context.current_user).current_versions
  end
end
