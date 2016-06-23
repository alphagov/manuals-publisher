class RepublishDocumentService
  def initialize(document_repository:, published_listeners: [], draft_listeners: [], document_id:)
    @document_repository = document_repository
    @published_listeners = published_listeners
    @draft_listeners = draft_listeners
    @document_id = document_id
  end

  def call
    if document.published?
      notify_published_listeners #calls [publishing_api_exporter, rummager]
    elsif  document.draft?
      notify_draft_listeners # [publishing_api_exporter]
    end

    document
  end

private
  attr_reader :document_repository, :published_listeners, :draft_listeners, :document_id

  def notify_listeners(listeners)
    listeners.each { |l| l.call(document, "republish") }
  end

  def notify_draft_listeners
    notify_listeners(draft_listeners)
  end

  def notify_published_listeners
    notify_listeners(published_listeners)
  end

  def document
    @document ||= document_repository.fetch(document_id)
  rescue KeyError => error
    raise DocumentNotFoundError.new(error)
  end

  class DocumentNotFoundError < StandardError; end
end
