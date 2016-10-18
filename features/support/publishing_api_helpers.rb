require "gds_api/test_helpers/publishing_api"
require "gds_api/test_helpers/publishing_api_v2"

module PublishingAPIHelpers
  include GdsApi::TestHelpers::PublishingApi
  include GdsApi::TestHelpers::PublishingApiV2

  def stub_publishing_api
    stub_default_publishing_api_put
    stub_default_publishing_api_put_draft
    stub_any_publishing_api_put_content
    stub_any_publishing_api_patch_links
    stub_any_publishing_api_publish
    # FIXME - Update these methods once https://github.com/alphagov/gds-api-adapters/pull/611
    # is merged
    stub_request(:post, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/content/.*/unpublish})
    stub_request(:post, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/content/.*/discard-draft})
  end
end
RSpec.configuration.include PublishingAPIHelpers, type: :feature
