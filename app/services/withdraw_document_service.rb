class WithdrawDocumentService
  def initialize(document_repository, listeners, context)
    @document_repository = document_repository
    @listeners = listeners
    @context = context
  end

  def call(document)
    @document = document
    withdraw
    persist
    notify_listeners

    document
  end

  private

  attr_reader :document_repository, :listeners, :context, :document

  def withdraw
    document.withdraw!
  end

  def persist
    document_repository.store(document)
  end

  def notify_listeners
    listeners.each { |l| l.call(document) }
  end
end
