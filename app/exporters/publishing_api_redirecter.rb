require "securerandom"

class PublishingAPIRedirecter
  def call(entity:, redirect_to_location:)
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
end
