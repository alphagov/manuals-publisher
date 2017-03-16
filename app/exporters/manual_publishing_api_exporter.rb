class ManualPublishingAPIExporter
  include PublishingAPIUpdateTypes

  PUBLISHING_API_SCHEMA_NAME = "manual".freeze
  PUBLISHING_API_DOCUMENT_TYPE = "manual".freeze

  def initialize(organisation, publication_logs, manual, update_type: nil)
    @export_recipient = Services.publishing_api_v2.method(:put_content)
    @organisation = organisation
    @manual_renderer = ManualRenderer.new
    @publication_logs = publication_logs
    @manual = manual
    @update_type = update_type
    check_update_type!(@update_type)
  end

  def call
    export_recipient.call(content_id, exportable_attributes)
  end

private

  attr_reader(
    :export_recipient,
    :organisation,
    :manual_renderer,
    :publication_logs,
    :manual,
  )

  def base_path
    "/#{manual.attributes[:slug]}"
  end

  def content_id
    manual.id
  end

  def updates_path
    [base_path, "updates"].join("/")
  end

  def exportable_attributes
    {
      base_path: base_path,
      schema_name: PUBLISHING_API_SCHEMA_NAME,
      document_type: PUBLISHING_API_DOCUMENT_TYPE,
      title: rendered_manual_attributes.fetch(:title),
      description: rendered_manual_attributes.fetch(:summary),
      update_type: update_type,
      publishing_app: "manuals-publisher",
      rendering_app: "manuals-frontend",
      routes: [
        {
          path: base_path,
          type: "exact",
        },
        {
          path: updates_path,
          type: "exact",
        }
      ],
      details: details_data,
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

  def update_type
    return @update_type if @update_type.present?
    ManualUpdateType.for(manual)
  end

  def rendered_manual_attributes
    @rendered_manual_attributes ||= manual_renderer.call(manual).attributes
  end

  def details_data
    {
      body: [
        {
          content_type: "text/govspeak",
          content: manual.attributes.fetch(:body)
        },
        {
          content_type: "text/html",
          content: rendered_manual_attributes.fetch(:body)
        }
      ],
      child_section_groups: [
        {
          title: "Contents",
          child_sections: sections,
        }
      ],
      change_notes: serialised_change_notes,
      organisations: [
        organisation_info
      ]
    }
  end

  def sections
    manual.documents.map { |d|
      {
        title: d.attributes.fetch(:title),
        description: d.attributes.fetch(:summary),
        base_path: "/#{d.attributes.fetch(:slug)}",
      }
    }
  end

  def serialised_change_notes
    publication_logs.change_notes_for(manual.attributes.fetch(:slug)).map { |publication|
      {
        base_path: "/#{publication.slug}",
        title: publication.title,
        change_note: publication.change_note,
        published_at: publication.published_at.iso8601,
      }
    }
  end

  def organisation_info
    {
      title: organisation["title"],
      abbreviation: organisation["details"]["abbreviation"],
      web_url: organisation["web_url"],
    }
  end
end
