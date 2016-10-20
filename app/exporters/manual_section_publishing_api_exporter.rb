class ManualSectionPublishingAPIExporter

  def initialize(export_recipent, organisation, document_renderer, manual, document)
    @export_recipent = export_recipent
    @organisation = organisation
    @document_renderer = document_renderer
    @manual = manual
    @document = document
  end

  def call
    export_recipent.call(content_id, exportable_attributes)
  end

private

  attr_reader :export_recipent, :document_renderer, :organisation, :manual, :document

  def content_id
    document.id
  end

  def base_path
    "/#{rendered_document_attributes.fetch(:slug)}"
  end

  def exportable_attributes
    {
      base_path: base_path,
      schema_name: "manual_section",
      document_type: "manual_section",
      title: rendered_document_attributes.fetch(:title),
      description: rendered_document_attributes.fetch(:summary),
      public_updated_at: rendered_document_attributes.fetch(:updated_at).iso8601,
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
    }
  end

  def details
    {
      body: [
        {
          content_type: "text/govspeak",
          content: document.attributes.fetch(:body)
        },
        {
          content_type: "text/html",
          content: rendered_document_attributes.fetch(:body)
        }
      ],
      manual: {
        base_path: "/#{manual.attributes.fetch(:slug)}",
      },
      organisations: [
        organisation_info
      ],
    }.tap do |details_hash|
      details_hash[:attachments] = attachments if document.attachments.present?
    end
  end

  def attachments
    document.attachments.map {|attachment| attachment_json_builder(attachment.attributes) }
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
    document.minor_update? ? "minor" : "major"
  end

  def rendered_document_attributes
    @rendered_document_attributes ||= document_renderer.call(document).attributes
  end

  def organisation_info
    {
      title: organisation["title"],
      abbreviation: organisation["details"]["abbreviation"],
      web_url: organisation["web_url"],
    }
  end
end
