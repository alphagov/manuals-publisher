require "services"
require "gds_api_constants"

class SectionPublishingAPIExporter
  def call(organisation, manual, section, version_type: nil)
    update_type = case version_type || section.version_type
                  when :new, :major
                    GdsApiConstants::PublishingApiV2::MAJOR_UPDATE_TYPE
                  when :minor
                    GdsApiConstants::PublishingApiV2::MINOR_UPDATE_TYPE
                  when :republish
                    GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE
                  else
                    raise "Unknown version type: #{section.version_type}"
                  end

    attributes = {
      base_path: "/#{section.slug}",
      schema_name: GdsApiConstants::PublishingApiV2::SECTION_SCHEMA_NAME,
      document_type: GdsApiConstants::PublishingApiV2::SECTION_DOCUMENT_TYPE,
      title: section.title,
      description: section.summary,
      update_type: update_type,
      publishing_app: GdsApiConstants::PublishingApiV2::PUBLISHING_APP,
      rendering_app: GdsApiConstants::PublishingApiV2::RENDERING_APP,
      routes: [
        {
          path: "/#{section.slug}",
          type: GdsApiConstants::PublishingApiV2::EXACT_ROUTE_TYPE,
        }
      ],
      details: {
        body: [
          {
            content_type: "text/govspeak",
            content: section.body
          },
          {
            content_type: "text/html",
            content: SectionPresenter.new(section).body
          }
        ],
        attachments: section.attachments.map do |attachment|
          {
            content_id: SecureRandom.uuid,
            title: attachment.title,
            url: attachment.file_url,
            updated_at: attachment.updated_at,
            created_at: attachment.created_at,
            content_type: attachment.content_type
          }
        end,
        manual: {
          base_path: "/#{manual.slug}",
        },
        organisations: [
          {
            title: organisation.title,
            abbreviation: organisation.abbreviation,
            web_url: organisation.web_url,
          }
        ],
      },
      locale: GdsApiConstants::PublishingApiV2::EDITION_LOCALE,
    }

    if manual.originally_published_at.present?
      attributes[:first_published_at] = manual.originally_published_at
      if manual.use_originally_published_at_for_public_timestamp?
        attributes[:public_updated_at] = manual.originally_published_at
      end
    end

    Services.publishing_api.put_content(section.uuid, attributes)
  end
end
