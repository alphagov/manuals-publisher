class PublishDocumentService
  def initialize(document_repository, listeners, context)
    @document_repository = document_repository
    @listeners = listeners
    @context = context
  end

  def call(document)
    @document = document
    publish
    persist

    document
  end

  private

  attr_reader :document_repository, :listeners, :context, :document

  def publish
    document.publish!

    listeners.each { |o| o.call(document) }
  end

  def persist
    document_repository.store(document)
  end

  def notify_listeners
    listeners.each do |listener|
      listener.call(document)
    end
  end
end
