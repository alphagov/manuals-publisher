require "services"
require "gds_api_constants"

class SectionPublishingAPIExporter
  include PublishingAPIUpdateTypes

  def initialize(organisation, manual, section, update_type: nil)
    @organisation = organisation
    @manual = manual
    @section = section
    @update_type = update_type
    check_update_type!(@update_type)
  end

  def call
    exportable_attributes = {
      base_path: "/#{section_presenter.slug}",
      schema_name: GdsApiConstants::PublishingApiV2::SECTION_SCHEMA_NAME,
      document_type: GdsApiConstants::PublishingApiV2::SECTION_DOCUMENT_TYPE,
      title: section_presenter.title,
      description: section_presenter.summary,
      update_type: update_type,
      publishing_app: GdsApiConstants::PublishingApiV2::PUBLISHING_APP,
      rendering_app: GdsApiConstants::PublishingApiV2::RENDERING_APP,
      routes: [
        {
          path: "/#{section_presenter.slug}",
          type: GdsApiConstants::PublishingApiV2::EXACT_ROUTE_TYPE,
        }
      ],
      details: details,
      locale: GdsApiConstants::PublishingApiV2::EDITION_LOCALE,
    }
    exportable_attributes.merge!(optional_exportable_attributes)

    Services.publishing_api.put_content(section.uuid, exportable_attributes)
  end

private

  attr_reader :organisation, :manual, :section

  def optional_exportable_attributes
    attrs = {}
    if manual.originally_published_at.present?
      attrs[:first_published_at] = manual.originally_published_at
      attrs[:public_updated_at] = manual.originally_published_at if manual.use_originally_published_at_for_public_timestamp?
    end
    attrs
  end

  def details
    {
      body: [
        {
          content_type: "text/govspeak",
          content: section.body
        },
        {
          content_type: "text/html",
          content: section_presenter.body
        }
      ],
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
    }.tap do |details_hash|
      details_hash[:attachments] = attachments if section.attachments.present?
    end
  end

  def attachments
    section.attachments.map do |attachment|
      {
        content_id: SecureRandom.uuid,
        title: attachment.title,
        url: attachment.file_url,
        updated_at: attachment.updated_at,
        created_at: attachment.created_at,
        content_type: attachment.content_type
      }
    end
  end

  def update_type
    return @update_type if @update_type.present?
    case section.version_type
    when :new, :major
      GdsApiConstants::PublishingApiV2::MAJOR_UPDATE_TYPE
    when :minor
      GdsApiConstants::PublishingApiV2::MINOR_UPDATE_TYPE
    else
      raise "Unknown version type: #{section.version_type}"
    end
  end

  def section_presenter
    @section_presenter ||= SectionPresenter.new(section)
  end
end
