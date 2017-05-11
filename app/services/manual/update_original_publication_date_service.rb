class Manual::UpdateOriginalPublicationDateService
  def initialize(manual_id:, attributes:, context:)
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
      # a nil change note will omit this update from publication logs
      section.update(change_note: nil)
    end
  end

  def export_draft_to_publishing_api
    Adapters.publishing.save(manual)
  end

  def fetch_manual
    Manual.find(manual_id, context.current_user)
  end
end
