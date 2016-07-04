class RepublishDocumentService
  def initialize(document_repository:, published_listeners: [], draft_listeners: [], withdrawn_listeners: [], document_id:)
    @document_repository = document_repository
    @published_listeners = published_listeners
    @draft_listeners = draft_listeners
    @withdrawn_listeners = withdrawn_listeners
    @document_id = document_id
  end

  def call
    notify_withdrawn_listeners if document.withdrawn?

    if document.published?
      notify_published_listeners # calls [publishing_api_exporter, rummager]
    elsif  document.draft?
      notify_draft_listeners # calls [publishing_api_exporter]
    end

    document
  end

private
  attr_reader :document_repository, :published_listeners, :draft_listeners, :withdrawn_listeners, :document_id

  # We should only pass an update_type of "republish" through for published
  # documents. Otherwise, we clobber the user's update_type for the draft.
  def notify_draft_listeners
    draft_listeners.each { |l| l.call(document) }
  end

  def notify_published_listeners
    published_listeners.each { |l| l.call(document, "republish") }
  end

  def notify_withdrawn_listeners
    withdrawn_listeners.each { |l| l.call(document) }
  end

  def document
    @document ||= document_repository.fetch(document_id)
  rescue KeyError => error
    raise DocumentNotFoundError.new(error)
  end

  class DocumentNotFoundError < StandardError; end
end
