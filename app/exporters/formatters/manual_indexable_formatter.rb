require "formatters/abstract_indexable_formatter"

class ManualIndexableFormatter < AbstractIndexableFormatter
  RUMMAGER_DOCUMENT_TYPE = "manual".freeze

  def initialize(manual)
    @manual = manual
  end

  def id
    root_path.join(@manual.slug).to_s
  end

  def type
    RUMMAGER_DOCUMENT_TYPE
  end

  def indexable_attributes
    {
      title: @manual.title,
      description: @manual.summary,
      link: root_path.join(@manual.slug).to_s,
      indexable_content: @manual.summary,
      public_timestamp: @manual.updated_at,
      content_store_document_type: type,
    }
  end
end
