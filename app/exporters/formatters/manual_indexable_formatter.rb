require "formatters/abstract_indexable_formatter"

class ManualIndexableFormatter < AbstractIndexableFormatter
  RUMMAGER_DOCUMENT_TYPE = "manual".freeze

  def type
    RUMMAGER_DOCUMENT_TYPE
  end

  def indexable_attributes
    {
      title: title,
      description: description,
      link: link,
      indexable_content: indexable_content,
      public_timestamp: public_timestamp,
      content_store_document_type: type,
    }
  end

private

  def indexable_content
    entity.summary # Manuals don't have a body
  end
end
