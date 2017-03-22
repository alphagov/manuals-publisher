class PublishManualService
  def initialize(manual_id:, manual_repository:, version_number:)
    @manual_id = manual_id
    @manual_repository = manual_repository
    @listeners = [
      PublicationLogger.new,
      PublishingApiDraftManualWithSectionsExporter.new,
      PublishingApiManualWithSectionsPublisher.new,
      RummagerManualWithSectionsExporter.new,
    ]
    @version_number = version_number
  end

  def call
    if versions_match?
      publish
      notify_listeners
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
    :listeners,
    :version_number,
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

  def notify_listeners
    listeners.each do |listener|
      listener.call(manual)
    end
  end

  def manual
    @manual ||= manual_repository.fetch(manual_id)
  end

  class VersionMismatchError < StandardError
  end
end
