require "gds_api/organisations"
require "gds_api/publishing_api_v2"

module Services
  def self.organisations
    @organisations ||= GdsApi::Organisations.new(ORGANISATIONS_API_BASE_PATH)
  end

  def self.publishing_api_v2
    @publishing_api_v2 ||= GdsApi::PublishingApiV2.new(
      Plek.new.find("publishing-api"),
      bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] || "example"
    )
  end
end
