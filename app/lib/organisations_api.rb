require "gds_api/organisations"

class OrganisationsApi
  def self.instance
    GdsApi::Organisations.new(ORGANISATIONS_API_BASE_PATH)
  end
end
