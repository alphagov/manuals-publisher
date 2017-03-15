require "gds_api/organisations"
require "gds_api/publishing_api"
require "gds_api/publishing_api_v2"
require "gds_api/rummager"

module Services
  def self.organisations
    @organisations ||= GdsApi::Organisations.new(ORGANISATIONS_API_BASE_PATH)
  end

  def self.publishing_api
    @publishing_api ||= GdsApi::PublishingApi.new(
      Plek.new.find("publishing-api"),
      bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] || "example",
      timeout: 30
    )
  end

  def self.publishing_api_v2
    @publishing_api_v2 ||= GdsApi::PublishingApiV2.new(
      Plek.new.find("publishing-api"),
      bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] || "example"
    )
  end

  def self.rummager
    @rummager_api ||= GdsApi::Rummager.new(Plek.new.find("search"))
  end
end
