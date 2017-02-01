class ManualDocumentAttachmentServiceRegistry < AbstractManualDocumentAttachmentServiceRegistry
private

  def repository
    RepositoryRegistry.create.manual_repository
  end
end
