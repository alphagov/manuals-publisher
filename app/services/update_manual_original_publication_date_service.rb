class UpdateManualOriginalPublicationDateService
  def initialize(manual_repository:, manual_id:, attributes:, context:)
    @manual_repository = manual_repository
    @manual_id = manual_id
    @attributes = attributes.slice(:originally_published_at, :use_originally_published_at_for_public_timestamp)
    @context = context
  end

  def call
    manual.draft
    update
    update_sections
    persist

    export_draft_to_publishing_api

    manual
  end

private

  attr_reader(
    :manual_id,
    :manual_repository,
    :attributes,
    :context,
  )

  def update
    manual.update(attributes)
  end

  def persist
    manual.save(context.current_user)
    @manual = fetch_manual
  end

  def manual
    @manual ||= fetch_manual
  end

  def update_sections
    manual.sections.each do |section|
      # a no-op update will force a new draft if we need it
      section.update({})
    end
  end

  def export_draft_to_publishing_api
    PublishingApiDraftManualWithSectionsExporter.new.call(manual)
  end

  def fetch_manual
    Manual.find(manual_id, context.current_user)
  end
end
