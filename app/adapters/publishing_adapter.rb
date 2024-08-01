require "securerandom"

class PublishingAdapter
  def self.unpublish(manual)
    Services.publishing_api.unpublish(manual.id, type: "gone")

    manual.sections.each do |section|
      Services.publishing_api.unpublish(section.uuid, type: "gone")
    end
  end

  def self.redirect_section(section, to:)
    Services.publishing_api.put_content(
      SecureRandom.uuid,
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
    )
  end
end
