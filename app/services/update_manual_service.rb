class UpdateManualService
  def initialize(manual_repository:, manual_id:, attributes:)
    @manual_repository = manual_repository
    @manual_id = manual_id
    @attributes = attributes
  end

  def call
    manual.draft
    update
    persist
    export_draft_to_publishing_api

    manual
  end

private

  attr_reader(
    :manual_id,
    :manual_repository,
    :attributes,
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

  def export_draft_to_publishing_api
    reloaded_manual = manual_repository[manual.id]
    PublishingApiDraftManualWithSectionsExporter.new.call(reloaded_manual)
  end
end
