class OrganisationalManualServiceRegistry < AbstractManualServiceRegistry
  def initialize(organisation_slug:)
    @organisation_slug = organisation_slug
  end

private

  attr_reader :organisation_slug

  def repository
    manual_repository_factory.call(organisation_slug)
  end

  def associationless_repository
    associationless_manual_repository_factory.call(organisation_slug)
  end

  def manual_repository_factory
    RepositoryRegistry.create
      .organisation_scoped_manual_repository_factory
  end

  def associationless_manual_repository_factory
    RepositoryRegistry.create
      .associationless_organisation_scoped_manual_repository_factory
  end
end
