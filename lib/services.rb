require "gds_api/organisations"

module Services
  def self.organisations
    @organisations ||= GdsApi::Organisations.new(ORGANISATIONS_API_BASE_PATH)
  end
end
