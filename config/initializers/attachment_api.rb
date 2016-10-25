require "gds_api/asset_manager"
require "plek"

# Attachable trait in govuk_content_models expects Ostruct response.
GdsApi.config.hash_response_for_requests = false

Attachable.asset_api_client = GdsApi::AssetManager.new(
  Plek.current.find("asset-manager"),
  bearer_token: ENV["ASSET_MANAGER_BEARER_TOKEN"],
)
