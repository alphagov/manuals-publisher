class ManualDocumentServiceRegistry < AbstractManualDocumentServiceRegistry
private

  def manual_repository
    ManualsPublisherWiring.get(:repository_registry).manual_repository
  end
end
