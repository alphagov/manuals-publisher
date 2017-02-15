class ManualDocumentAttachmentServiceRegistry < AbstractManualDocumentAttachmentServiceRegistry
private

  def repository
    ManualsPublisherWiring.get(:repository_registry).manual_repository
  end
end
