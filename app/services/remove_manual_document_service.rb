class RemoveManualDocumentService
  def initialize(manual_repository, context, listeners:)
    @manual_repository = manual_repository
    @context = context
    @listeners = listeners
  end

  def call
    raise ManualDocumentNotFoundError.new(document_id) unless document.present?

    document.update(change_note_params)

    if document.valid?
      # Removing a document always makes the manual a draft
      manual.draft

      remove
      persist
      notify_listeners
    end

    [manual, document]
  end

private

  attr_reader :manual_repository, :context, :listeners

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
    document_params = context.params.fetch("document")
    {
      "minor_update" => document_params.fetch("minor_update", "0"),
      "change_note" => document_params.fetch("change_note", ""),
    }
  end

  def notify_listeners
    listeners.each do |listener|
      listener.call(document, manual)
    end
  end

  class ManualNotFoundError < StandardError; end
  class ManualDocumentNotFoundError < StandardError; end
end
