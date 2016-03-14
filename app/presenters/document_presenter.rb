require 'govspeak'

class DocumentPresenter

  def initialize(document)
    @document = document
  end

  def to_json
    {
      content_id: document.content_id,
      base_path: document.base_path,
      title: document.title,
      description: document.summary,
      document_type: document.document_type,
      schema_name: document.schema_name,
      format: "specialist_document",
      publishing_app: "specialist-publisher",
      rendering_app: "specialist-frontend",
      locale: "en",
      phase: document.phase,
      public_updated_at: public_updated_at,
      details: {
        body: document.body,
        metadata: metadata,
        change_history: change_history,
      },
      routes: [
        {
          path: document.base_path,
          type: "exact",
        }
      ],
      redirects: [],
      update_type: document.update_type,
    }
  end

private

  attr_reader :document

  def metadata
    document.format_specific_fields.map { |f|
      {
        f => document.send(f)
      }
    }.reduce({}, :merge).merge({
      document_type: document.publishing_api_document_type,
      bulk_published: document.bulk_published,
    }).reject { |k, v| v.blank? }
  end

  def public_updated_at
    document.public_updated_at.to_datetime.rfc3339
  end

  def change_history
    case document.update_type
    when "major"
      document.change_history + [{ public_timestamp: public_updated_at, note: document.change_note || "First published." }]
    when "minor"
      document.change_history
    end
  end
end
