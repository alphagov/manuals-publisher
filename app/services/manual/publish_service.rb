require "adapters"

class Manual::PublishService
  def initialize(manual_id:, version_number:, context:)
    @manual_id = manual_id
    @version_number = version_number
    @context = context
  end

  def call
    if versions_match?
      publish
      log_publication
      export_draft_to_publishing_api
      publish_to_publishing_api
      add_to_search_index
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
    manual.save(context.current_user)
  end

  def log_publication
    PublicationLogger.new.call(manual)
  end

  def export_draft_to_publishing_api
    Adapters.publishing.save(manual)
  end

  def publish_to_publishing_api
    Adapters.publishing.publish(manual)
  end

  def add_to_search_index
    Adapters.search_index.add(manual)
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  class VersionMismatchError < StandardError
  end
end
