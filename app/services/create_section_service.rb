class CreateSectionService
  def initialize(manual_repository:, context:)
    @manual_repository = manual_repository
    @context = context
  end

  def call
    @new_section = manual.build_section(section_params)

    if new_section.valid?
      manual.draft
      manual_repository.store(manual)
      export_draft_manual_to_publishing_api
      export_draft_section_to_publishing_api
    end

    [manual, new_section]
  end

private

  attr_reader :manual_repository, :context

  attr_reader :new_section

  def manual
    @manual ||= Manual.find(context.params.fetch("manual_id"), context.current_user)
  end

  def export_draft_manual_to_publishing_api
    PublishingApiDraftManualExporter.new.call(manual)
  end

  def export_draft_section_to_publishing_api
    PublishingApiDraftSectionExporter.new.call(new_section, manual)
  end

  def section_params
    context.params.fetch("section")
  end
end
