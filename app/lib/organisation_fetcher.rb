require "services"

class OrganisationFetcher
  def self.fetch(organisation_slug)
    @organisations ||= {}
    @organisations[organisation_slug] ||= Services.organisations.organisation(organisation_slug)
  end
end
