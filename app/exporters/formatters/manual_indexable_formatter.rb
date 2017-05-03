require "formatters/abstract_indexable_formatter"

class ManualIndexableFormatter < AbstractIndexableFormatter
  RUMMAGER_DOCUMENT_TYPE = "manual".freeze

  def id
    root_path.join(entity.slug).to_s
  end

  def type
    RUMMAGER_DOCUMENT_TYPE
  end

  def indexable_attributes
    {
      title: entity.title,
      description: entity.summary,
      link: root_path.join(entity.slug).to_s,
      indexable_content: entity.summary,
      public_timestamp: entity.updated_at,
      content_store_document_type: type,
    }
  end
end
