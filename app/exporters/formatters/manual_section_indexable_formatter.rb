require "formatters/abstract_indexable_formatter"

class ManualSectionIndexableFormatter < AbstractIndexableFormatter
  RUMMAGER_DOCUMENT_TYPE = "manual_section".freeze

  def initialize(section, manual)
    @entity = section
    @manual = manual
  end

  def type
    RUMMAGER_DOCUMENT_TYPE
  end

private

  attr_reader :manual

  def extra_attributes
    {
      manual: manual_slug,
    }
  end

  def manual_slug
    with_leading_slash(manual.slug)
  end

  def title
    "#{manual.title}: #{entity.title}"
  end

  def description
    entity.summary
  end

  def link
    with_leading_slash(entity.slug)
  end

  def indexable_content
    entity.body
  end

  def public_timestamp
    nil
  end
end
