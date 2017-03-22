class CreateSectionService
  def initialize(manual_repository:, context:)
    @manual_repository = manual_repository
    @context = context
  end

  def call
    @new_document = manual.build_section(document_params)

    if new_document.valid?
      manual.draft
      manual_repository.store(manual)
      export_draft_manual_to_publishing_api
      export_draft_section_to_publishing_api
    end

    [manual, new_document]
  end

private

  attr_reader :manual_repository, :context

  attr_reader :new_document

  def manual
    @manual ||= manual_repository.fetch(context.params.fetch("manual_id"))
  end

  def export_draft_manual_to_publishing_api
    PublishingApiDraftManualExporter.new.call(manual)
  end

  def export_draft_section_to_publishing_api
    PublishingApiDraftSectionExporter.new.call(new_document, manual)
  end

  def document_params
    context.params.fetch("section")
  end
end
