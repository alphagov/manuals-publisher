require "securerandom"

class Publishing::RedirectAdapter
  def self.redirect_section(section, to:)
    redirect_content_id = SecureRandom.uuid
    Services.publishing_api.put_content(
      redirect_content_id,
      document_type: "redirect",
      schema_name: "redirect",
      publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
      base_path: "/#{section.slug}",
      redirects: [
        {
          path: "/#{section.slug}",
          type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
          destination: to,
        },
      ],
      update_type: "major",
    )
    Services.publishing_api.publish(redirect_content_id)
  end
end
