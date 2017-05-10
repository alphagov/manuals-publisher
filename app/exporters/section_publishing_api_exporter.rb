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
    Services.publishing_api.put_content(content_id, exportable_attributes)
  end

private

  attr_reader :organisation, :manual, :section

  def content_id
    section.uuid
  end

  def base_path
    "/#{section_presenter.slug}"
  end

  def exportable_attributes
    {
      base_path: base_path,
      schema_name: GdsApiConstants::PublishingApiV2::SECTION_SCHEMA_NAME,
      document_type: GdsApiConstants::PublishingApiV2::SECTION_DOCUMENT_TYPE,
      title: section_presenter.title,
      description: section_presenter.summary,
      update_type: update_type,
      publishing_app: "manuals-publisher",
      rendering_app: "manuals-frontend",
      routes: [
        {
          path: base_path,
          type: "exact",
        }
      ],
      details: details,
      locale: "en",
    }.merge(optional_exportable_attributes)
  end

  def optional_exportable_attributes
    attrs = {}
    if manual.originally_published_at.present?
      attrs[:first_published_at] = manual.originally_published_at.iso8601
      attrs[:public_updated_at] = manual.originally_published_at.iso8601 if manual.use_originally_published_at_for_public_timestamp?
    end
    attrs
  end

  def details
    {
      body: [
        {
          content_type: "text/govspeak",
          content: section.attributes.fetch(:body)
        },
        {
          content_type: "text/html",
          content: section_presenter.body
        }
      ],
      manual: {
        base_path: "/#{manual.attributes.fetch(:slug)}",
      },
      organisations: [
        organisation_info
      ],
    }.tap do |details_hash|
      details_hash[:attachments] = attachments if section.attachments.present?
    end
  end

  def attachments
    section.attachments.map { |attachment| attachment_json_builder(attachment.attributes) }
  end

  def build_content_type(file_url)
    return unless file_url
    extname = File.extname(file_url).delete(".")
    "application/#{extname}"
  end

  def attachment_json_builder(attributes)
    {
      content_id: attributes.fetch("content_id", SecureRandom.uuid),
      title: attributes.fetch("title", nil),
      url: attributes.fetch("file_url", nil),
      updated_at: attributes.fetch("updated_at", nil),
      created_at: attributes.fetch("created_at", nil),
      content_type: build_content_type(attributes.fetch("file_url", nil))
    }
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

  def organisation_info
    {
      title: organisation.title,
      abbreviation: organisation.abbreviation,
      web_url: organisation.web_url,
    }
  end
end
