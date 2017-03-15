class OrganisationalManualServiceRegistry < AbstractManualServiceRegistry
  def initialize(organisation_slug:)
    @organisation_slug = organisation_slug
  end

  attr_reader :organisation_slug

  def associationless_repository
    associationless_manual_repository_factory = RepositoryRegistry.create
      .associationless_organisation_scoped_manual_repository_factory
    associationless_manual_repository_factory.call(organisation_slug)
  end
end
