class OrganisationFetcher
  def self.instance
    @organisations ||= {}
    ->(organisation_slug) {
      @organisations[organisation_slug] ||= OrganisationsApi.instance.organisation(organisation_slug)
    }
  end
end
