module ManualsPublisher
  extend self

  def document_services(document_type)
    builder = case document_type
              when "manual"
                ManualBuilder.create
              end
    AbstractDocumentServiceRegistry.new(
      repository: document_repositories.for_type(document_type),
      builder: builder,
      observers: observer_registry(document_type),
    )
  end

private

  def document_repositories
    RepositoryRegistry.create
  end
end
