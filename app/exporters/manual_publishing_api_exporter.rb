class ManualPublishingAPIExporter
  include PublishingAPIUpdateTypes

  PUBLISHING_API_SCHEMA_NAME = "manual".freeze
  PUBLISHING_API_DOCUMENT_TYPE = "manual".freeze

  def initialize(organisation, manual, update_type: nil)
    @organisation = organisation
    @manual = manual
    @update_type = update_type
    check_update_type!(@update_type)
  end

  def call
    Services.publishing_api.put_content(content_id, exportable_attributes)
  end

private

  attr_reader(
    :organisation,
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
      title: presented_manual.title,
      description: presented_manual.summary,
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

  def presented_manual
    @presented_manual ||= ManualPresenter.new(manual)
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
          content: presented_manual.body
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
    manual.sections.map { |d|
      {
        title: d.attributes.fetch(:title),
        description: d.attributes.fetch(:summary),
        base_path: "/#{d.attributes.fetch(:slug)}",
      }
    }
  end

  def serialised_change_notes
    PublicationLog.change_notes_for(manual.attributes.fetch(:slug)).map { |publication|
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
      title: organisation.title,
      abbreviation: organisation.abbreviation,
      web_url: organisation.web_url,
    }
  end
end
