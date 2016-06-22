require "formatters/abstract_indexable_formatter"

class ManualIndexableFormatter < AbstractIndexableFormatter
  def type
    "manual"
  end

private
  def extra_attributes
    {}
  end

  def indexable_content
    entity.summary # Manuals don't have a body
  end
end
