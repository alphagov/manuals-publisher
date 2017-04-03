class UpdateSectionService
  def initialize(manual_repository:, context:)
    @manual_repository = manual_repository
    @context = context
  end

  def call
    section.update(section_params)

    if section.valid?
      manual.draft
      manual_repository.store(manual)
      export_draft_manual_to_publishing_api
      export_draft_section_to_publishing_api
    end

    [manual, section]
  end

private

  attr_reader :manual_repository, :context, :listeners

  def section
    @section ||= manual.sections.find { |s| s.id == section_id }
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def section_id
    context.params.fetch("id")
  end

  def manual_id
    context.params.fetch("manual_id")
  end

  def section_params
    context.params.fetch("section")
  end

  def export_draft_manual_to_publishing_api
    PublishingApiDraftManualExporter.new.call(manual)
  end

  def export_draft_section_to_publishing_api
    PublishingApiDraftSectionExporter.new.call(section, manual)
  end
end
