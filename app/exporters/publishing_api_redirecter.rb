require "securerandom"

class PublishingAPIRedirecter
  def initialize(publishing_api:, entity:, redirect_to_location:)
    @publishing_api = publishing_api
    @entity = entity
    @redirect_to_location = redirect_to_location
  end

  def call
    publishing_api.put_content(SecureRandom.uuid, exportable_attributes)
  end

private

  attr_reader(
    :publishing_api,
    :entity,
    :redirect_to_location
  )

  def exportable_attributes
    {
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
    }
  end
end
