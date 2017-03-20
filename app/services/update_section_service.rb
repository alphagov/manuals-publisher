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
      call_publishing_api_draft_manual_exporter
      call_publishing_api_draft_section_exporter
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

  def call_publishing_api_draft_section_exporter
    PublishingApiDraftSectionExporter.new.call(document, manual)
  end

  def call_publishing_api_draft_manual_exporter
    PublishingApiDraftManualExporter.new.call(document, manual)
  end
end
