class RemoveSectionService
  def initialize(manual_repository, context)
    @manual_repository = manual_repository
    @context = context
  end

  def call
    raise SectionNotFoundError.new(document_id) unless document.present?

    document.update(change_note_params)

    if document.valid?
      # Removing a document always makes the manual a draft
      manual.draft

      remove
      persist
      export_draft_manual_to_publishing_api
      discard_section_via_publishing_api
    end

    [manual, document]
  end

private

  attr_reader :manual_repository, :context

  def remove
    manual.remove_document(document_id)
  end

  def persist
    manual_repository.store(manual)
  end

  def document
    @document ||= manual.documents.find { |d| d.id == document_id }
  end

  def manual
    @manual ||= manual_repository.fetch(manual_id)
  rescue KeyError
    raise ManualNotFoundError.new(manual_id)
  end

  def document_id
    context.params.fetch("id")
  end

  def manual_id
    context.params.fetch("manual_id")
  end

  def change_note_params
    document_params = context.params.fetch("section")
    {
      "minor_update" => document_params.fetch("minor_update", "0"),
      "change_note" => document_params.fetch("change_note", ""),
    }
  end

  def discard_section_via_publishing_api
    PublishingApiDraftSectionDiscarder.new.call(document, manual)
  end

  def export_draft_manual_to_publishing_api
    PublishingApiDraftManualExporter.new.call(document, manual)
  end

  class ManualNotFoundError < StandardError; end
  class SectionNotFoundError < StandardError; end
end
