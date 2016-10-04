module ManualsPublisher
  extend self

  def attachment_services(document_type)
    AbstractAttachmentServiceRegistry.new(
      repository: document_repositories.for_type(document_type)
    )
  end

  def document_services(document_type)
    AbstractDocumentServiceRegistry.new(
      repository: document_repositories.for_type(document_type),
      builder: ManualsPublisherWiring.get("#{document_type}_builder".to_sym),
      observers: observer_registry(document_type),
    )
  end

  def view_adapter(document)
    view_adapters.for_document(document)
  end

  def document_types
    OBSERVER_MAP.keys
  end

private
  OBSERVER_MAP = {}.freeze

  ORGANISATIONS = {}

  def view_adapters
    ManualsPublisherWiring.get(:view_adapter_registry)
  end

  def document_repositories
    ManualsPublisherWiring.get(:repository_registry)
  end

  def observer_registry(document_type)
    OBSERVER_MAP.fetch(document_type).new(ORGANISATIONS.fetch(document_type, []))
  end
end
