class OrganisationalManualDocumentAttachmentServiceRegistry < AbstractManualDocumentAttachmentServiceRegistry
  def initialize(organisation_slug:)
    @organisation_slug = organisation_slug
  end

  def repository
    manual_repository_factory = RepositoryRegistry.create
      .organisation_scoped_manual_repository_factory
    manual_repository_factory.call(organisation_slug)
  end

private

  attr_reader :organisation_slug
end
