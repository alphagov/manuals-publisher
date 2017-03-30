class CreateManualService
  def initialize(manual_repository:, manual_builder:, attributes:)
    @manual_repository = manual_repository
    @manual_builder = manual_builder
    @attributes = attributes
  end

  def call
    if manual.valid?
      persist
      export_draft_to_publishing_api
    end

    manual
  end

private

  attr_reader(
    :manual_repository,
    :manual_builder,
    :attributes,
  )

  def manual
    @manual ||= Manual.build(attributes)
  end

  def persist
    manual_repository.store(manual)
  end

  def export_draft_to_publishing_api
    reloaded_manual = manual_repository[manual.id]
    PublishingApiDraftManualWithSectionsExporter.new.call(reloaded_manual)
  end
end
