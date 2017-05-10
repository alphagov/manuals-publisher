require "securerandom"

class PublishingAPIRedirecter
  def initialize(entity:, redirect_to_location:)
    @entity = entity
    @redirect_to_location = redirect_to_location
  end

  def call
    Services.publishing_api.put_content(
      SecureRandom.uuid,
      document_type: 'redirect',
      schema_name: 'redirect',
      publishing_app: "manuals-publisher",
      base_path: "/#{entity.slug}",
      redirects: [
        {
          path: "/#{entity.slug}",
          type: "exact",
          destination: redirect_to_location
        }
      ],
    )
  end

private

  attr_reader(
    :entity,
    :redirect_to_location
  )
end
