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

  def document_types
    OBSERVER_MAP.keys
  end

private
  def document_repositories
    ManualsPublisherWiring.get(:repository_registry)
  end
end
