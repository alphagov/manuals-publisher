require "gds_api/asset_manager"
require "plek"

module AttachmentApi
  def self.client
    @client ||= GdsApi::AssetManager.new(
      Plek.current.find("asset-manager"),
      bearer_token: ENV["ASSET_MANAGER_BEARER_TOKEN"],
    )
  end
end
