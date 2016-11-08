class RemoveManualDocumentService
  def initialize(manual_repository, context, listeners:)
    @manual_repository = manual_repository
    @context = context
    @listeners = listeners
  end

  def call
    raise ManualDocumentNotFoundError.new(document_id) unless document.present?
    # Removing a document always makes the manual a draft
    manual.draft

    remove
    persist
    notify_listeners

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
  rescue KeyError => error
    raise ManualNotFoundError.new(manual_id)
  end

  def document_id
    context.params.fetch("id")
  end

  def manual_id
    context.params.fetch("manual_id")
  end

  def notify_listeners
    listeners.each do |listener|
      listener.call(document, manual)
    end
  end

  class ManualNotFoundError < StandardError; end
  class ManualDocumentNotFoundError < StandardError; end
end
