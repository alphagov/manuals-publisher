module ManualsPublisher
  extend self

  def document_services(document_type)
    AbstractDocumentServiceRegistry.new(
      repository: document_repositories.for_type(document_type),
      builder: ManualsPublisherWiring.get("#{document_type}_builder".to_sym),
      observers: observer_registry(document_type),
    )
  end

private
  def document_repositories
    ManualsPublisherWiring.get(:repository_registry)
  end
end
