class UpdateSectionService
  def initialize(manual_repository:, context:)
    @manual_repository = manual_repository
    @context = context
  end

  def call
    document.update(document_params)

    if document.valid?
      manual.draft
      manual_repository.store(manual)
      export_draft_manual_to_publishing_api
      export_draft_section_to_publishing_api
    end

    [manual, document]
  end

private

  attr_reader :manual_repository, :context, :listeners

  def document
    @document ||= manual.documents.find { |d| d.id == document_id }
  end

  def manual
    @manual ||= manual_repository.fetch(manual_id)
  end

  def document_id
    context.params.fetch("id")
  end

  def manual_id
    context.params.fetch("manual_id")
  end

  def document_params
    context.params.fetch("section")
  end

  def export_draft_manual_to_publishing_api
    PublishingApiDraftManualExporter.new.call(manual)
  end

  def export_draft_section_to_publishing_api
    PublishingApiDraftSectionExporter.new.call(document, manual)
  end
end
