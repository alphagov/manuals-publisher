class UpdateManualOriginalPublicationDateService
  def initialize(manual_repository:, manual_id:, attributes:, listeners:)
    @manual_repository = manual_repository
    @manual_id = manual_id
    @attributes = attributes.slice(:originally_published_at, :use_originally_published_at_for_public_timestamp)
    @listeners = listeners
  end

  def call
    manual.draft
    update
    update_documents
    persist

    notify_listeners

    manual
  end

private

  attr_reader(
    :manual_id,
    :manual_repository,
    :attributes,
    :listeners,
  )

  def update
    manual.update(attributes)
  end

  def persist
    manual_repository.store(manual)
    @manual = fetch_manual
  end

  def manual
    @manual ||= fetch_manual
  end

  def update_documents
    manual.documents.each do |document|
      # a no-op update will force a new draft if we need it
      document.update({})
    end
  end

  def notify_listeners
    listeners.each do |listener|
      listener.call(manual)
    end
  end

  def fetch_manual
    manual_repository.fetch(manual_id)
  end
end
