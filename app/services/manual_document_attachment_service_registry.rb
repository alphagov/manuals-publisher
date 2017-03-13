class ManualDocumentAttachmentServiceRegistry < AbstractManualDocumentAttachmentServiceRegistry

  def repository
    RepositoryRegistry.create.manual_repository
  end
end
