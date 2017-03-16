require "services"

class OrganisationFetcher
  def self.instance
    @organisations ||= {}
    ->(organisation_slug) {
      @organisations[organisation_slug] ||= Services.organisations.organisation(organisation_slug)
    }
  end
end
