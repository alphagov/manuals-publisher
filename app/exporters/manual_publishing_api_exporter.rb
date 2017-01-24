class ManualPublishingAPIExporter

  def initialize(export_recipent, organisation, manual_renderer, publication_logs, manual)
    @export_recipent = export_recipent
    @organisation = organisation
    @manual_renderer = manual_renderer
    @publication_logs = publication_logs
    @manual = manual
  end

  def call
    export_recipent.call(content_id, exportable_attributes)
  end

private

  attr_reader(
    :export_recipent,
    :organisation,
    :manual_renderer,
    :publication_logs,
    :manual
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
      schema_name: "manual",
      document_type: "manual",
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
    # The first edition to be sent to the publishing api must always be sent as
    # a major update
    return "major" unless manual.has_ever_been_published?

    # Otherwise our update type status depends on the update type status
    # of our children if any of them are major we are major (and they
    # have to send a major for their first edition too).
    all_documents_are_minor? ? "minor" : "major"
  end

  def all_documents_are_minor?
    manual.
      documents.
      select(&:needs_exporting?).
      all? { |d|
        d.minor_update? && d.has_ever_been_published?
      }
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
