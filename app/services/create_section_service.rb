class CreateSectionService
  def initialize(manual_repository:, context:)
    @manual_repository = manual_repository
    @context = context
  end

  def call
    @new_document = manual.build_document(document_params)

    if new_document.valid?
      manual.draft
      manual_repository.store(manual)
      call_publishing_api_draft_manual_exporter
      call_publishing_api_draft_section_exporter
    end

    [manual, new_document]
  end

private

  attr_reader :manual_repository, :listeners, :context

  attr_reader :new_document

  def manual
    @manual ||= manual_repository.fetch(context.params.fetch("manual_id"))
  end

  def call_publishing_api_draft_section_exporter
    PublishingApiDraftSectionExporter.new.call(new_document, manual)
  end

  def call_publishing_api_draft_manual_exporter
    PublishingApiDraftManualExporter.new.call(new_document, manual)
  end

  def document_params
    context.params.fetch("section")
  end
end
