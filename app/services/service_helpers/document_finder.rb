class DocumentFinder
  def initialize(document_repository, service, context, service_accepts_nil_document: false)
    @document_repository = document_repository
    @service = service
    @context = context
    @service_accepts_nil_document = service_accepts_nil_document
  end

  def call
    service.call(current_document) if current_document || service_accepts_nil_document 
  end

private
  attr_reader :document_repository, :context, :service, :service_accepts_nil_document

  def current_document
    document_repository.fetch(document_id, nil)
  end

  def document_id
    context.params.fetch("id", nil)
  end
end
