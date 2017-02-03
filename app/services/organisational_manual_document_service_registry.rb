class OrganisationalManualDocumentServiceRegistry < AbstractManualDocumentServiceRegistry
  def initialize(organisation_slug:)
    @organisation_slug = organisation_slug
  end

private
  attr_reader :organisation_slug

  def manual_repository_factory
    RepositoryRegistry.create.
      organisation_scoped_manual_repository_factory
  end

  def manual_repository
    manual_repository_factory.call(organisation_slug)
  end
end
