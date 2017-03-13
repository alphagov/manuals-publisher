require "formatters/abstract_indexable_formatter"

class ManualIndexableFormatter < AbstractIndexableFormatter
  RUMMAGER_DOCUMENT_TYPE = "manual".freeze

  def type
    RUMMAGER_DOCUMENT_TYPE
  end

private

  def extra_attributes
    {}
  end

  def indexable_content
    entity.summary # Manuals don't have a body
  end
end
