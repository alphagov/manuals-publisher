require "gds_api/asset_manager"
require "gds_api/content_store"
require "gds_api/organisations"
require "gds_api/publishing_api"
require "gds_api/link_checker_api"

module Services
  def self.attachment_api
    @attachment_api ||= GdsApi::AssetManager.new(
      Plek.find("asset-manager"),
      bearer_token: ENV["ASSET_MANAGER_BEARER_TOKEN"] || "12345678",
    )
  end

  def self.content_store
    @content_store ||= GdsApi::ContentStore.new(Plek.find("content-store"))
  end

  def self.organisations
    @organisations ||= GdsApi::Organisations.new(Plek.new.website_root)
  end

  def self.publishing_api
    @publishing_api ||= GdsApi::PublishingApi.new(
      Plek.find("publishing-api"),
      bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] || "example",
    )
  end

  def self.link_checker_api
    @link_checker_api ||= GdsApi::LinkCheckerApi.new(
      Plek.find("link-checker-api"),
      bearer_token: ENV["LINK_CHECKER_API_BEARER_TOKEN"],
    )
  end
end
