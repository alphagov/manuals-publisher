class PublishManualService
  def initialize(manual_id:, manual_repository:, version_number:, context:)
    @manual_id = manual_id
    @manual_repository = manual_repository
    @version_number = version_number
    @context = context
  end

  def call
    if versions_match?
      publish
      log_publication
      export_draft_to_publishing_api
      publish_to_publishing_api
      export_to_rummager
      persist
    else
      raise VersionMismatchError.new(
        %(The manual with id '#{manual.id}' could not be published due to a version mismatch.
          The version to publish was '#{version_number}' but the current version was '#{manual.version_number}')
      )
    end

    manual
  end

private

  attr_reader(
    :manual_id,
    :manual_repository,
    :version_number,
    :context,
  )

  def versions_match?
    version_number == manual.version_number
  end

  def publish
    manual.publish
  end

  def persist
    manual_repository.store(manual)
  end

  def log_publication
    PublicationLogger.new.call(manual)
  end

  def export_draft_to_publishing_api
    PublishingApiDraftManualWithSectionsExporter.new.call(manual)
  end

  def publish_to_publishing_api
    PublishingApiManualWithSectionsPublisher.new.call(manual)
  end

  def export_to_rummager
    RummagerManualWithSectionsExporter.new.call(manual)
  end

  def manual
    @manual ||= manual_repository.fetch(manual_id)
  end

  class VersionMismatchError < StandardError
  end
end
