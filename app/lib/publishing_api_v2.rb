require "gds_api/publishing_api_v2"

class PublishingApiV2
  def self.instance
    @publishing_api_v2 ||= GdsApi::PublishingApiV2.new(
      Plek.new.find("publishing-api"),
      bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] || "example"
    )
  end
end
