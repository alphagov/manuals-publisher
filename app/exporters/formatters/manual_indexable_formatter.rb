require "formatters/abstract_indexable_formatter"

class ManualIndexableFormatter < AbstractIndexableFormatter
  RUMMAGER_DOCUMENT_TYPE = "manual".freeze

  def id
    path
  end

  def type
    RUMMAGER_DOCUMENT_TYPE
  end

  def indexable_attributes
    {
      title: entity.title,
      description: entity.summary,
      link: path,
      indexable_content: entity.summary,
      public_timestamp: entity.updated_at,
      content_store_document_type: type,
    }
  end

private

  def path
    root_path.join(entity.slug).to_s
  end
end
