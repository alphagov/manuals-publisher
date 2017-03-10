module ManualsPublisher
  extend self

  def document_services(document_type)
    AbstractDocumentServiceRegistry.new(
      repository: document_repositories.for_type(document_type),
      builder: ManualBuilder.create,
      observers: observer_registry(document_type),
    )
  end

private

  def document_repositories
    RepositoryRegistry.create
  end
end
