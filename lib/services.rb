require "gds_api/asset_manager"
require "gds_api/content_store"
require "gds_api/organisations"
require "gds_api/publishing_api"
require "gds_api/publishing_api_v2"
require "gds_api/rummager"

module Services
  def self.attachment_api
    @attachment_api ||= GdsApi::AssetManager.new(
      Plek.find("asset-manager"),
      bearer_token: ENV["ASSET_MANAGER_BEARER_TOKEN"] || '12345678',
    )
  end

  def self.content_store
    @content_store ||= GdsApi::ContentStore.new(Plek.find("content-store"))
  end

  def self.organisations
    @organisations ||= GdsApi::Organisations.new(Plek.find("whitehall-admin"))
  end

  def self.publishing_api_v2
    @publishing_api_v2 ||= GdsApi::PublishingApiV2.new(
      Plek.find("publishing-api"),
      bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] || "example"
    )
  end

  def self.rummager
    @rummager_api ||= GdsApi::Rummager.new(Plek.find("rummager"))
  end
end
