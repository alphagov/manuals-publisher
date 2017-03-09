require "securerandom"

class PublishingAPIRedirecter
  def initialize(publishing_api:, entity:, redirect_to_location:)
    @publishing_api = publishing_api
    @entity = entity
    @redirect_to_location = redirect_to_location
  end

  def call
    raise 'GdsApi::PublishingApi#put_content_item was removed in gds-api-adapters v38.0.0'
  end

private

  attr_reader(
    :publishing_api,
    :entity,
    :redirect_to_location
  )

  def base_path
    "/#{entity.slug}"
  end

  def exportable_attributes
    {
      format: "redirect",
      publishing_app: "manuals-publisher",
      update_type: "major",
      base_path: base_path,
      redirects: [
        {
          path: base_path,
          type: "exact",
          destination: redirect_to_location
        }
      ],
      content_id: content_id,
    }
  end

  def content_id
    @_content_id ||= SecureRandom.uuid
  end
end
