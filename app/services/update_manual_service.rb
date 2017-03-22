class UpdateManualService
  def initialize(manual_repository:, manual_id:, attributes:)
    @manual_repository = manual_repository
    @manual_id = manual_id
    @attributes = attributes
    @listeners = [PublishingApiDraftManualWithSectionsExporter.new]
  end

  def call
    manual.draft
    update
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
  end

  def manual
    @manual ||= manual_repository.fetch(manual_id)
  end

  def notify_listeners
    reloaded_manual = manual_repository[manual.id]
    listeners.each do |listener|
      listener.call(reloaded_manual)
    end
  end
end
