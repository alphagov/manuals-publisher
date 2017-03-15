class OrganisationalSectionServiceRegistry < AbstractSectionServiceRegistry
  def initialize(organisation_slug:)
    @organisation_slug = organisation_slug
  end
end
